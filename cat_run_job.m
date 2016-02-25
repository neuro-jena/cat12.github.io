function cat_run_job(job,tpm,subj)
% run CAT 
% ______________________________________________________________________
%
% Initialization function of the CAT preprocessing. 
%  * creation of the subfolder structure (if active)
%  * check of image resolution (avoid scans with very low resolution)
%  * noise correction (ISARNLM)
%  * interpolation 
%  * affine preprocessing (APP)
%    >> cat_run_job_APP_init
%    >> cat_run_job_APP_final
%  * affine registration
%  * initial SPM preprocessing
%
%   cat_run_job(job,tpm,subj)
% 
%   job  .. SPM job structure with main parameter
%   tpm  .. tissue probability map (hdr structure)
%   subj .. file name
% ______________________________________________________________________
% Christian Gaser
% $Id$

%#ok<*WNOFF,*WNON>

    stime = clock;

    
    % print current CAT release number and subject file
    [n,r] = cat_version;
    str  = sprintf('CAT12 r%s',r);
    str2 = spm_str_manip(job.channel(1).vols{subj},['a' num2str(70 - length(str))]);
    cat_io_cprintf([0.2 0.2 0.8],'\n%s\n%s: %s%s\n%s\n',...
          repmat('-',1,72),str,...
          repmat(' ',1,70 - length(str) - length(str2)),str2,...
          repmat('-',1,72));
    clear r str str2

    
    % create subfolders if not exist
    pth = spm_fileparts(job.channel(1).vols{subj}); 
    if job.extopts.subfolders
      folders = {'mri','report'};
      for i=1:numel(folders)
        if ~exist(fullfile(pth,folders{i}),'dir')
          mkdir(fullfile(pth,folders{i}));
        end
      end
      if ~exist(fullfile(pth,'surf'),'dir') && job.output.surface
        mkdir(fullfile(pth,'surf'));
      end
      if ~exist(fullfile(pth,'label'),'dir') && job.output.ROI
        mkdir(fullfile(pth,'label'));
      end
      
      mrifolder    = 'mri';
      reportfolder = 'report';
    else
      mrifolder    = '';
      reportfolder = '';
    end
    
    
    %  -----------------------------------------------------------------
    %  check resolution properties
    %  -----------------------------------------------------------------
    %  There were some images that should not be processed. So we have  
    %  to check for high slice thickness and low resolution.
    %  -----------------------------------------------------------------
    for n=1:numel(job.channel) 
      V = spm_vol(job.channel(n).vols{subj});
      vx_vol = sqrt(sum(V.mat(1:3,1:3).^2));

      if any(vx_vol>5)  % too thin slices
        error('CAT:cat_main:TooLowResolution', sprintf(...
             ['Voxel resolution has to be better than 5 mm in any dimension \n' ...
              'for reliable CAT preprocessing! \n' ...
              'This image has a resolution %0.2fx%0.2fx%0.2f mm%s. '], ... 
                vx_vol,char(179))); %#ok<SPERR>
      end
      if prod(vx_vol)>27  % too small voxel volume (smaller than 3x3x3 mm3)
        error('CAT:cat_main:TooHighVoxelVolume', ...
             ['Voxel volume has to be smaller than 10 mm%s (around 3x3x3 mm%s) to \n' ...
              'allow a reliable CAT preprocessing! \n' ...
              'This image has a voxel volume of %0.2f mm%s. '], ...
              char(179),char(179),prod(vx_vol),char(179));
      end
      if max(vx_vol)/min(vx_vol)>8 % isotropy 
        error('CAT:cat_main:TooStrongIsotropy', sprintf(...
             ['Voxel isotropy (max(vx_size)/min(vx_size)) has to be smaller than 8 to \n' ...
              'allow a reliable CAT preprocessing! \n' ...
              'This image has a resolution %0.2fx%0.2fx%0.2f mm%s and a isotropy of %0.2f. '], ...
              vx_vol,char(179),max(vx_vol)/min(vx_vol))); %#ok<SPERR>
      end
    end


    % save original file name 
    for n=1:numel(job.channel) 
      job.channel(n).vols0{subj} = job.channel(n).vols{subj};
    end
    
    
    
    %  noise-correction
    %  -----------------------------------------------------------------
    if job.extopts.sanlm && job.extopts.NCstr
      %{
        stime = cat_io_cmd('NLM-filter');
      %} 

        for n=1:numel(job.channel) 
            V = spm_vol(job.channel(n).vols{subj});
            Y = single(spm_read_vols(V));
            Y(isnan(Y)) = 0;
          %{
            % use isarnlm-filter only if voxel size <= 0.7mm
            if any(round(vx_vol*100)/100<=0.70) && strcmp(job.extopts.species,'human')
                if job.extopts.verb>1, fprintf('\n'); end
                Y = cat_vol_isarnlm(Y,V,job.extopts.verb>1);   % use iterative multi-resolution multi-threaded version
                if job.extopts.verb>1, cat_io_cmd(' '); end
            else
                cat_sanlm(Y,3,1,0);          % use multi-threaded version
            end
           %}
            Vn = cat_io_writenii(V,Y,mrifolder,'n','noise corrected','float32',[0,1],[1 0 0]);
            job.channel(n).vols{subj} = Vn.fname;
            clear Y V Vn;
        end

%        fprintf('%4.0fs\n',etime(clock,stime));     
    else
       if job.extopts.APP>0 || ~strcmp(job.extopts.species,'human')
         % this is necessary because of the real masking of the T1 data 
         % for spm_preproc8 that include rewriting the image!
         for n=1:numel(job.channel) 
           [pp,ff,ee] = spm_fileparts(job.channel(n).vols{subj}); 
           ofname  = fullfile(pp,[ff ee]); 
           nfname  = fullfile(pp,mrifolder,['n' ff '.nii']); 
           copyfile(ofname,nfname); 
           job.channel(n).vols{subj} = nfname;
         end
       end
    end
   
      
    
    %% Interpolation
    %  -----------------------------------------------------------------
    %  The interpolation can help to reduce problems for morphological
    %  operations for low resolutions and strong isotropic images. 
    %  Especially for Dartel registration a native resolution higher than the Dartel 
    %  resolution helps to reduce normalization artifacts of the
    %  deformations. Furthermore, even if artifacts can be reduced by the final smoothing
    %  it is much better to avoid them.  
    vx_vold = min(job.extopts.vox,sqrt(sum(tpm.V(1).mat(1:3,1:3).^2))); clear Vt; % Dartel resolution 
    for n=1:numel(job.channel) 

      % prepare header of resampled volume
      Vi        = spm_vol(job.channel(n).vols{subj}); 
      vx_vol    = sqrt(sum(Vi.mat(1:3,1:3).^2));
  
      % we have to look for the name of the field due to the GUI job struct generation! 
      restype   = char(fieldnames(job.extopts.restypes));
      switch restype
        case 'native'
          vx_voli  = vx_vol;
        case 'fixed', 
          vx_voli  = min(vx_vol ,job.extopts.restypes.(restype)(1) ./ ...
                     ((vx_vol > (job.extopts.restypes.(restype)(1)+job.extopts.restypes.(restype)(2)))+eps));
          vx_voli  = max(vx_voli,job.extopts.restypes.(restype)(1) .* ...
                     ( vx_vol < (job.extopts.restypes.(restype)(1)-job.extopts.restypes.(restype)(2))));
        case 'best'
          vx_voli  = min(vx_vol ,job.extopts.restypes.(restype)(1) ./ ...
                     ((vx_vol > (job.extopts.restypes.(restype)(1)+job.extopts.restypes.(restype)(2)))+eps));
          vx_voli  = min(vx_vold,vx_voli); % guarantee Dartel resolution
        otherwise 
          error('cat_run_job:restype','Unknown resolution type ''%s''. Choose between ''fixed'',''native'', and ''best''.',restype)
      end

      
      
      % interpolation 
      if any( (vx_vol ~= vx_voli) )  
       
        stime = cat_io_cmd(sprintf('Internal resampling (%4.2fx%4.2fx%4.2fmm > %4.2fx%4.2fx%4.2fmm)',vx_vol,vx_voli));
       
        Vi        = rmfield(Vi,'private'); 
        imat      = spm_imatrix(Vi.mat); 
        Vi.dim    = round(Vi.dim .* vx_vol./vx_voli);
        imat(7:9) = vx_voli .* sign(imat(7:9));
        Vi.mat    = spm_matrix(imat);

        Vn = spm_vol(job.channel(n).vols{subj}); 
        Vn = rmfield(Vn,'private'); 
        if ~(job.extopts.sanlm && job.extopts.NCstr) 
          % if no noise correction we have to add the 'n' prefix here
          [pp,ff,ee] = spm_fileparts(Vn.fname);
          Vi.fname = fullfile(pp,mrifolder,['n' ff ee]);
          job.channel(n).vols{subj} = Vi.fname;
        end
        if job.extopts.sanlm==0
          [pp,ff,ee,dd] = spm_fileparts(Vn.fname); 
          Vi.fname = fullfile(pp,mrifolder,['n' ff ee dd]);
          job.channel(n).vols{subj} = Vi.fname;
        end
        cat_vol_imcalc(Vn,Vi,'i1',struct('interp',6,'verb',0));
        vx_vol = vx_voli;

        fprintf('%4.0fs\n',etime(clock,stime));    
      end
      clear Vi Vn;
    end
    
    
    %  prepare SPM preprocessing structure 
    images = job.channel(1).vols{subj};
    for n=2:numel(job.channel)
        images = char(images,job.channel(n).vols{subj});
    end

    obj.image    = spm_vol(images);
    spm_check_orientations(obj.image);

    obj.fwhm     = job.opts.fwhm;
    obj.biasreg  = cat(1,job.opts.biasreg);
    obj.biasfwhm = cat(1,job.opts.biasfwhm);
    obj.tpm      = tpm;
    obj.lkp      = [];
    if all(isfinite(cat(1,job.tissue.ngaus))),
        for k=1:numel(job.tissue),
            obj.lkp = [obj.lkp ones(1,job.tissue(k).ngaus)*k];
        end;
    end
    obj.reg      = job.opts.warpreg;
    obj.samp     = job.opts.samp;              
       


    %% Initial affine registration.
    %  -----------------------------------------------------------------
    %  APP option with subparameter
    %  Skull-stripping is helpful for correcting affine registration of neonates and other species. 
    %  Bias correction is important for the affine registration.
    %  However, the first registation can fail,
    if ~strcmp(job.extopts.species,'human'), job.extopts.APP=3; end
    
    Affine  = eye(4);
    [pp,ff] = spm_fileparts(job.channel(1).vols{subj});
    Pbt = fullfile(pp,mrifolder,['brainmask_' ff '.nii']);
    Pb  = char(job.extopts.brainmask);
    Pt1 = char(job.extopts.T1);
    if ~isempty(job.opts.affreg)      
          
        %% first affine registration (with APP)
        try 
            VG = spm_vol(Pt1);
        catch
            pause(rand(1))
            VG = spm_vol(Pt1);
        end
        VF = spm_vol(obj.image(1));

        % Rescale images so that globals are better conditioned
        VF.pinfo(1:2,:) = VF.pinfo(1:2,:)/spm_global(VF);
        VG.pinfo(1:2,:) = VG.pinfo(1:2,:)/spm_global(VG);

        
        % APP step 1 rough bias correction 
        % --------------------------------------------------------------
        % Already for the rought initial affine registration a simple  
        % bias corrected and intensity scaled image is required, because
        % high head intensities can disturb the whole process.
        % --------------------------------------------------------------
        % ds('l2','',vx_vol,Ym, Yt + 2*Ybg,obj.image.private.dat(:,:,:)/WMth,Ym,60)
        if job.extopts.APP  
            stime = cat_io_cmd('APP1: rough bias correction'); 
            [Ym,Yt,Ybg,WMth] = cat_run_job_APP_init(single(obj.image.private.dat(:,:,:)),...
                vx_vol,job.extopts.verb);
            
            stime = cat_io_cmd('Coarse Affine registration','','',1,stime); 
            
            % write data to VF
            VF.dt         = [spm_type('UINT8') spm_platform('bigend')];
            VF.dat(:,:,:) = uint8(Ym * 200); 
            VF.pinfo      = repmat([1;0],1,size(Ym,3));
            clear WI; 
            
            % smoothing
            resa  = obj.samp*3; % definine smoothing by sample size
            VF1   = spm_smoothto8bit(VF,resa);
            VG1   = spm_smoothto8bit(VG,resa);
        else
            % standard approach with static resa value and no VG smoothing
            stime = cat_io_cmd('Coarse Affine registration'); 
            resa  = 8;
            VF1   = spm_smoothto8bit(VF,resa);
            VG1   = VG; 
        end
          
        % prepare affine parameter 
        aflags     = struct('sep',resa,'regtype',job.opts.affreg,'WG',[],'WF',[],'globnorm',0);
        aflags.sep = max(aflags.sep,max(sqrt(sum(VG(1).mat(1:3,1:3).^2))));
        aflags.sep = max(aflags.sep,max(sqrt(sum(VF(1).mat(1:3,1:3).^2))));

        % affine resistration
        try
            spm_plot_convergence('Init','Coarse Affine Registration','Mean squared difference','Iteration');
        catch
            spm_chi2_plot('Init','Coarse Affine Registration','Mean squared difference','Iteration');
        end
        if job.extopts.APP~=4
            warning off 
            try 
              [Affine0, affscale]  = spm_affreg(VG1, VF1, aflags, eye(4)); Affine = Affine0; 
            catch
              affscale = 0; 
            end
            % if we get totally strange values (very small/large brains) 
            % then we obtain problematic data or more often the affine
            % registration found something else more interesting than 
            % the brain. So we used the standard parameter with two
            % major differences: regtype=subj and globnorm = 1
            if affscale>3 || affscale<0.5
              aflags     = struct('sep',resa,'regtype','subj','WG',[],'WF',[],'globnorm',1); % subject + globnorm!
              aflags.sep = max(aflags.sep,max(sqrt(sum(VG(1).mat(1:3,1:3).^2))));
              aflags.sep = max(aflags.sep,max(sqrt(sum(VF(1).mat(1:3,1:3).^2))));
              [Affine0, affscale]  = spm_affreg(VG1, VF1, aflags, eye(4)); Affine = Affine0; 
            end
            warning on
        end
          
        
        
        %% APP step 2 - brainmasking and second tissue separated bias correction  
        %  ---------------------------------------------------------
        %  The second part of APP maps a brainmask to native space and 
        %  refines it by morphologic operations and region-growing to
        %  adapt for worse initial affine alignments. It is important
        %  that the mask covers the whole brain, whereas additional
        %  masked head is here less problematic.
        %  ---------------------------------------------------------
        %    ds('l2','',vx_vol,Ym,Yb,Ym,Yp0,90)
        if job.extopts.APP>2
            % apply (first affine) registration on the default brain mask
            VFa = VF; 
            if job.extopts.APP~=3, VFa.mat = Affine0 * VF.mat; else Affine = eye(4); affscale = 1; end
            if isfield(VFa,'dat'), VFa = rmfield(VFa,'dat'); end
            [Vmsk,Yb] = cat_vol_imcalc([VFa,spm_vol(Pb)],Pbt,'i2',struct('interp',3,'verb',0)); Yb = Yb>0.5; 
       
            stime = cat_io_cmd(sprintf('APP%d: fine bias correction',job.extopts.APP),'','',1,stime); 
    
            [Ym,Yp0,Yb] = cat_run_job_APP_final(single(obj.image.private.dat(:,:,:)),...
                Ym,Yb,Ybg,vx_vol,job.extopts.gcutstr,job.extopts.verb);
            stime = cat_io_cmd('Affine registration','','',1,stime); 
                                  
            % msk T1 & TPM
            if 0 % with mask
              VF.dat(:,:,:) = cat_vol_ctype(Ym*200 .* Yb); 
              VF1 = spm_smoothto8bit(VF,aflags.sep/2);

              VG1 = spm_smoothto8bit(VG,0.1);
              VG1.dat = VG1.dat .* uint8(spm_read_vols(spm_vol(Pb))>0.5); 
              VG1 = spm_smoothto8bit(VG1,aflags.sep/2);
            else % without mask
              VF.dat(:,:,:) =  cat_vol_ctype(Ym*200); 
              VF1 = spm_smoothto8bit(VF,aflags.sep/2);
              VG1 = spm_smoothto8bit(VG,aflags.sep/4);
            end
        elseif job.extopts.APP==1 || job.extopts.APP==2
            % msk T1 & TPM
            stime = cat_io_cmd('Affine registration','','',1,stime); 
            VF.dat(:,:,:) =  cat_vol_ctype(Ym*200); 
            VF1 = spm_smoothto8bit(VF,aflags.sep/2);
            VG1 = spm_smoothto8bit(VG,aflags.sep/2);
        else
            % standard approach 
            stime = cat_io_cmd('Affine registration','','',1,stime); 
            VF1 = spm_smoothto8bit(VF,aflags.sep/2);
            VG1 = spm_smoothto8bit(VG,0.5); 
        end

          
        % fine affine registration 
        try
            spm_plot_convergence('Init','Coarse Affine Registration 2','Mean squared difference','Iteration');
        catch
            spm_chi2_plot('Init','Coarse Affine Registration 2','Mean squared difference','Iteration');
        end
        aflags.sep = aflags.sep/2; 
        warning off
        [Affine1,affscale] = spm_affreg(VG1, VF1, aflags, Affine, affscale);  
        warning on
        if affscale>3 || affscale<0.5
          aflags     = struct('sep',resa,'regtype','subj','WG',[],'WF',[],'globnorm',1); % subject + globnorm!
          aflags.sep = max(aflags.sep,max(sqrt(sum(VG(1).mat(1:3,1:3).^2))));
          aflags.sep = max(aflags.sep,max(sqrt(sum(VF(1).mat(1:3,1:3).^2))));
          [Affine1,affscale] = spm_affreg(VG1, VF1, aflags, Affine, affscale);  %#ok<NASGU>
        end
        if ~any(isnan(Affine1(1:3,:))), Affine = Affine1; end
        clear VG1 VF1
    end
    
    
    %%
    if job.extopts.APP>1
        % rewrite bias correctd, but not skull-stripped image
        % obj.image.private.dat(:,:,:) = single(max(-WMth*0.1,min(4*WMth,Ym * th))); 
        % add temporary skull-stripped images
        Ysrc = single(obj.image.private.dat(:,:,:)); 
        if exist('Yb','var')
            th = cat_stat_nanmean(Ysrc(Yb(:) & Ysrc(:)>cat_stat_nanmean(Ysrc(Yb(:))))) / ...
                 cat_stat_nanmean(Ym(Yb(:)   & Ym(:)>cat_stat_nanmean(Ym(Yb(:)))));
        else % only initial bias correction
            th = WMth;
        end
        
        if job.extopts.APP==4
            obj.msk       = VF; 
            obj.msk.pinfo = repmat([255;0],1,size(Yb,3));
            obj.msk.dt    = [spm_type('uint8') spm_platform('bigend')];
            obj.msk.dat(:,:,:) = uint8(Yb); 
            obj.msk       = spm_smoothto8bit(obj.msk,0.1); 
        else
            obj.image.dat(:,:,:) = single(max(-WMth*0.1,min(4*WMth,Ym * th))); 
        end
        if job.extopts.APP==4
            Ybd = cat_vol_morph(cat_vol_morph(Yb,'d',1),'lc',1); % be shure that all brain tissue is included
            obj.image.dat(:,:,:) = single(max(-WMth*0.1,min(4*WMth,Ym * th .* Ybd))); % masking in dat 
            obj.image.private.dat(:,:,:) = single(max(-WMth*0.1,min(4*WMth,Ym * th .* Ybd))); % masking in the file
        else
            obj.image.dat(:,:,:) = single(max(-WMth*0.1,min(4*WMth,Ym * th))); 
        end
        obj.image.dt    = [spm_type('FLOAT32') spm_platform('bigend')];
        obj.image.pinfo = repmat([1;0],1,size(Ysrc,3));
        clear Ysrc; 
    end

    if job.extopts.APP
      stime = cat_io_cmd(sprintf('SPM preprocessing 1 (APP=%d):',job.extopts.APP),'','',1,stime);
    else
      stime = cat_io_cmd('SPM preprocessing 1:','','',1,stime);
    end
        
        
        
    %% Fine Affine Registration with 3 mm sampling distance
    %  This does not work for non human (or very small brains)
    if strcmp('human',job.extopts.species) 
        spm_plot_convergence('Init','Fine Affine Registration','Mean squared difference','Iteration');
        warning off 
        Affine2 = spm_maff8(obj.image(1),obj.samp,(obj.fwhm+1)*16,obj.tpm,Affine ,job.opts.affreg); 
        Affine3 = spm_maff8(obj.image(1),obj.samp,obj.fwhm,       obj.tpm,Affine2,job.opts.affreg);
        warning on  
        if ~any(isnan(Affine3(1:3,:))), Affine = Affine3; end
    end
    obj.Affine = Affine;

    % set original non-bias corrected image
    if job.extopts.APP==1
      obj.image = spm_vol(images);
    end
    
    %% SPM preprocessing 1
    %  ds('l2','a',0.5,Ysrc/WMth,Yb,Ysrc/WMth,Yb,140);
    warning off 
    try 
        res = spm_preproc8(obj);
    catch
        if (job.extopts.sanlm && job.extopts.NCstr) || any( (vx_vol ~= vx_voli) ) || ~strcmp(job.extopts.species,'human') 
            [pp,ff,ee] = spm_fileparts(job.channel(1).vols{subj});
            delete(fullfile(pp,[ff,ee]));
        end
        error('CAT:cat_run_job:spm_preproc8','Error in spm_preproc8. Check image and orientation. \n');
    end
    warning on 
        
    if job.extopts.debug==2
        % save information for debuging and OS test
        [pth,nam] = spm_fileparts(job.channel(1).vols0{subj}); 
        tmpmat = fullfile(pth,reportfolder,sprintf('%s_%s_%s.mat',nam,'runjob','postpreproc8')); 
        save(tmpmat,'obj','res','Affine','Affine0','Affine1','Affine3');     
    end 
       
        
    fprintf('%4.0fs\n',etime(clock,stime));   
    
    %error('Affine Registration test error')
    
    
    %% check contrast
    Tgw = [mean(res.mn(res.lkp==1)) mean(res.mn(res.lkp==2))]; 
    Tth = [
      max( min(mean(res.mn(res.lkp==3)) , max(Tgw)+abs(diff(Tgw))),min(Tgw)-abs(diff(Tgw)) ) ... % csf with limit for T2!
      mean(res.mn(res.lkp==1)) ... gm
      mean(res.mn(res.lkp==2)) ... wm 
    ];
    
    % inactive preprocessing of inverse images (PD/T2) 
    if job.extopts.INV==0 && any(diff(Tth)<=0)
      error('CAT:cat_main:BadImageProperties', ...
      ['CAT12 is designed to work only on highres T1 images.\n' ...
       'T2/PD preprocessing can be forced on your own risk by setting \n' ...
       '''cat12.extopts.INV=1'' in the cat default file. If this was a highres \n' ...
       'T1 image than the initial segmentation seemed to be corrupded, maybe \n' ...
       'by alignment problems (check image orientation).']);    
    end
            
    
    %% call main processing
    res.stime  = stime;
    res.image0 = spm_vol(job.channel(1).vols0{subj}); 
    cat_main(res,obj.tpm,job);
    
    % delete denoised/interpolated image
    if (job.extopts.sanlm && job.extopts.NCstr) || any( (vx_vol ~= vx_voli) ) || ~strcmp(job.extopts.species,'human') 
      [pp,ff,ee] = spm_fileparts(job.channel(1).vols{subj});
      delete(fullfile(pp,[ff,ee]));
    end
%%
return
%=======================================================================

