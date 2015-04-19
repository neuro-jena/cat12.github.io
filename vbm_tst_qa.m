function varargout = vbm_tst_qa(action,varargin)
% VBM Preprocessing T1 Quality Assurance
% ______________________________________________________________________
% 
% Estimation of image quality measures like noise, inhomogeneity,
% contrast, resolution, etc. and scaling for school marks. 
%
% [QAS,QAM] = vbm_vol_qa(action,varargin)
% 
%
% 1) Use GUI interface to choose segmenation and automatic setting of 
%    original and modified image (if available)
%     [QAS,QAM] = vbm_vol_qa()                = vbm_vol_qa('p0')
%
%     [QAS,QAM] = vbm_vol_qa('p0'[,opt])      - p0 class image
%     [QAS,QAM] = vbm_vol_qa('p#'[,opt])      - p1,p2,p3 class images
%     [QAS,QAM] = vbm_vol_qa('c#'[,opt])      - c1,c2,c3 class images
%     [QAS,QAM] = vbm_vol_qa('*#'[,opt])      - csf,gm,wm class images
%     [QAS,QAM] = vbm_vol_qa('p0',Pp0[,opt])           - no GUI call
%     [QAS,QAM] = vbm_vol_qa('p#',Pp1,Pp2,Pp3,[,opt])  - no GUI call
%     [QAS,QAM] = vbm_vol_qa('c#',Pc1,Pc2,Pc3,[,opt])  - no GUI call
%     [QAS,QAM] = vbm_vol_qa('c#',Pcsf,Pgm,Pwm,[,opt]) - no GUI call
%
%
% 2) Use GUI interface to choose all images like for other segmenations
%    and modalities with a similar focus of CSF, GM, and WM tissue 
%    contrast such as PD, T2, or FLASH. 
%     [QAS,QAM] = vbm_vol_qa('p0+'[,opt])     - p0 class image  
%     [QAS,QAM] = vbm_vol_qa('p#+'[,opt])     - p1,p2,p3 class images  
%     [QAS,QAM] = vbm_vol_qa('c#+'[,opt])     - c1,c2,c3 class images 
%     [QAS,QAM] = vbm_vol_qa('*#+'[,opt])     - csf,gm,wm class images
%     [QAS,QAM] = vbm_vol_qa('p0+',Pp0,Po[,Pm,opt])         - no GUI call
%     [QAS,QAM] = vbm_vol_qa('p#+',Pp1,Pp2,Pp3,Po[,Pm,opt]) - no GUI call
%     [QAS,QAM] = vbm_vol_qa('c#+',Pc1,Pc2,Pc3,Po[,Pm,opt]) - no GUI call
%
% 
% 3) Use GUI interface to choose all images. I.e. for other segmenations
%    and modalities without focus of GM-WM contrast such as DTI MTI. 
%     [�not implemented yet ]
%
%
% 4) VBM12 internal preprocessing interface 
%    (this is the processing case that is also called in all other cases)
%    [QAS,QAM] = vbm_vol_qa('vbm12',Yp0,Po,Ym,res[,opt])
%
%
%   Pp0 - segmentation files (p0*.nii)
%   Po  - original files (*.nii)
%   Pm  - modified files (m*.nii)
%   Yp0 - segmentation image matrix
%   Ym  - modified image matrix
%
%   opt            = parameter structure
%   opt.verb       = verbose level  [ 0=nothing | 1=points | 2*=times ]
%   opt.redres     = resolution in mm for intensity scaling [ 4* ];
%   opt.write_csv  = final cms-file
%   opt.write_xml  = images base xml-file
%   opt.sortQATm   = sort QATm output
%     opt.orgval     = original QAM results (no marks)
%     opt.recalc     =
%     opt.avgfactor  = 
%   opt.prefix     = prefix of xml output file (default vbm_*.xml) 
%
% ______________________________________________________________________
% Robert Dahnke 
% Structural Brain Mapping Group
% University Jena
%
% $Id$
% ______________________________________________________________________

% ______________________________________________________________________
% - Um einen RMS test mit dem mT zu machen, k�nnten man ggf. sp�ter mal
%   soweit korrekte bilder mit einem st�rbias versehen und dann 
%   anschlie�end gucken wie gut man wieder zum original kommt ...
% - Aufl�sungstest wie bei dicke?
% ______________________________________________________________________

%#ok<*ASGLU>

  rev = '$Rev$';
  % init output
  QAS = struct(); QAM = struct(); 
  vbm_qa_warnings = struct('identifier',{},'message',{});
  vbm_warnings    = struct('identifier',{},'message',{});
  if nargout>0, varargout = cell(1,nargout); end
  
  % no input and setting of default options
  if nargin==0, action='p0'; end 
  if isstruct(action)
    Pp0 = action.data;
    action = 'p0';
  end
  if nargin>1 && isstruct(varargin{end}) && isstruct(varargin{end})
    opt  = vbm_check('checkinopt',varargin{end},defaults);
    nopt = 1; 
  else
    opt  = defaults;
    nopt = 0;
  end

  % check input by action
  switch action
    case {'p0','p0+'}
    % segment image cases
      if nargin<=3
        if (nargin-nopt)<2  
          Pp0 = cellstr(spm_select(inf,'image',...
            'select p0-segment image',{},pwd,'^p0.*')); 
          if isempty(Pp0{1}), return; end
        else
          Pp0 = varargin{1};
        end
        if numel(action)==2
          Po = Pp0; Pm = Pp0;
          for fi=1:numel(Pp0)
            [pp,ff,ee] = spm_fileparts(Pp0{fi});

            Po{fi} = fullfile(pp,[ff(3:end) ee]); 
            Pm{fi} = fullfile(pp,[opt.mprefix  ff(3:end) ee]);
            Pmv{fi} = fullfile(pp,['m' ff(3:end) ee]); %#ok<AGROW>
            if ~exist(Pm{fi},'file') && strcmp(opt.mprefix,'nm') && exist(Pmv{fi},'file')
              fprintf('Preparing %s.\n',Pmv{fi});
              vbm_vol_sanlm(Pmv{fi},'n');
            end

            if ~exist(Po{fi},'file'), Po{fi}=''; end
            if ~exist(Pm{fi},'file'), Pm{fi}=''; end
          end
        else
          Po = cellstr(spm_select(repmat(numel(Pp0),1,2),...
            'image','select original image(s)',{},pwd,'.*')); 
          Pm = cellstr(spm_select(repmat(numel(Pp0),1,2),...
            'image','select modified image(s)',{},pwd,'.*')); 
        end
      elseif nargin<=5
        Pp0 = varargin{1};
        Po  = varargin{2};
        Pm  = varargin{3};
      else
        error('MATLAB:vbm_vol_qa:inputerror',...
          'Wrong number/structure of input elements!'); 
      end
    case {'p#','c#','*#','p#+','c#+','*#+'}
    % tissue class image cases
      if nargin-1<=2 % GUI 
        if (nargin-nopt)<2 
          if action(1)=='p' || action(1)=='c'
            % vbm/spm case
            Pcsf = cellstr(spm_select(inf,'image',...
              'select p1-segment image',{},pwd,['^' action(1) '1.*'])); 
            if isempty(Pcsf{1}), return; end
            Pgm=Pcsf; Pwm=Pcsf;
            for fi=1:numel(Pcsf)
              [pp,ff,ee] = spm_fileparts(Pcsf{fi});

              Pgm{fi} = fullfile(pp,[action(1) '2' ff(3:end) ee]); 
              Pwm{fi} = fullfile(pp,[action(1) '3' ff(3:end) ee]); 
            end
          else 
            Pcsf = cellstr(spm_select(inf,'image',...
              'select CSF segment image(s)',{},pwd,'.*')); 
            if isempty(Pcsf{1}), return; end
            %Pgm  = cellstr(spm_select(repmat(numel(Pcsf),1,2),...
            %  'image','select GM segment image(s)',{},pwd,'.*')); 
            %Pwm  = cellstr(spm_select(repmat(numel(Pcsf),1,2),...
            %  'image','select WM segment image(s)',{},pwd,'.*')); 
          end 
          if numel(action)==2
            Pp0=Pcsf; Po=Pcsf; Pm=Pcsf;
            for fi=1:numel(Pcsf)
              [pp,ff,ee] = spm_fileparts(Pcsf{fi});
              Po{fi}  = fullfile(pp,[ff(3:end) ee]);
              Pm{fi}  = fullfile(pp,['m'  ff(3:end) ee]);
              Pp0{fi} = fullfile(pp,['p0' ff(3:end) ee]);
            end 
          else
            Po = cellstr(spm_select(repmat(numel(Pcsf),1,2),...
              'image','select original image(s)',{},pwd,'.*')); 
            Pm = cellstr(spm_select(repmat(numel(Pcsf),1,2),...
              'image','select modified image(s)',{},pwd,'.*')); 
            Pp0=Pcsf;
            for fi=1:numel(Pcsf)
              [pp,ff,ee] = spm_fileparts(Pcsf{fi});
              Pp0{fi} = fullfile(pp,['p0' ff(3:end) ee]);
            end 
          end

          % wie komm ich zum p0???
        else
          Pp0 = varargin{1};
        end
      elseif nargin==5 || nargin==6
      else
        error('MATLAB:vbm_vol_qa:inputerror',...
          'Wrong number/structure of input elements!'); 
      end

      Yp0 = 1;
    case 'vbm12'
      % VBM12 internal input
      if nargin>3 
        Yp0 = varargin{1};
        Vo  = spm_vol(varargin{2});
        Yo  = single(spm_read_vols(Vo));    
        Ym  = varargin{3}; 
        res = varargin{4};
        vbm_warnings = varargin{5};
        species = varargin{6};
        
        opt.verb = 0;
        
        % reduce to original native space if it was interpolated
        if any(size(Yp0)~=Vo.dim)
          if isfield(Vo,'private'), Vo = rmfield(Vo,'private'); end
          if isfield(Vo,'mat0'),    Vo = rmfield(Vo,'mat0');    end
          Vo.dat = zeros(Vo.dim,'single'); Vo.dt(1) = 16; Vo.pinfo(3) = 0;
          
          Vp0t          = res.image;
          if isfield(Vp0t,'private'), Vp0t = rmfield(Vp0t,'private'); end
          if isfield(Vp0t,'mat0'),    Vp0t = rmfield(Vp0t,'mat0'); end
          Vp0t.dt(1)    = 16;
          Vp0t.pinfo(3) = 0;
          Vp0t.dat      = Yp0;

          % resampling and corrections of the Yp0
         % Vp0t       = spm_write_vol(Vp0t,double(Yp0));
          [Vtpm,Yp0] = vbm_vol_imcalc(Vp0t,Vo,'i1',struct('interp',6,'verb',0));
          rf         = 50;
          Yp0        = single(Yp0);
          Yp0r       = round(Yp0*rf)/rf;
          YMR        = false(size(Yp0));
          for i=1:4, YMR = YMR | (Yp0>(i-1/rf) & Yp0<(i+1/rf)); end
          Yp0(YMR)   = Yp0r(YMR); clear YMR Ynr;
          
          % resampling of the corrected image
          Vp0t.dat   = Ym;
          [Vtpm,Ym]  = vbm_vol_imcalc(Vp0t,Vo,'i1',struct('interp',6,'verb',0)); 
          Ym         = single(Ym);
        end
        
      else
        error('MATLAB:vbm_vol_qa:inputerror',...
          'Wrong number/structure of input elements!'); 
      end
    otherwise
      error('MATLAB:vbm_vol_qa:inputerror',...
        'Wrong number/structure of input elements!'); 
  end
  if ~exist('species','var'), species='human'; end
    
  
  %
  % --------------------------------------------------------------------
  [QA,QMAfn]  = vbm_stat_marks('init'); 
  stime  = clock;
  
  
  
  % Print options
  % --------------------------------------------------------------------
  opt.snspace = [70,7,3];
  Cheader = {'scan'};
  Theader = sprintf(sprintf('%%%ds:',opt.snspace(1)-1),'scan');
  Tline   = sprintf('%%5d) %%%ds:',opt.snspace(1)-8);
  Tline2  = sprintf('%%5d) %%6s%%%ds:',opt.snspace(1)-14); 
  Tavg    = sprintf('%%%ds:',opt.snspace(1)-1);
  TlineE  = sprintf('%%5d) %%%ds: %%s',opt.snspace(1)-7);
  for fi=1:numel(QMAfn)
    Cheader = [Cheader QMAfn{fi}]; %#ok<AGROW>
    Theader = sprintf(sprintf('%%s%%%ds',opt.snspace(2)),Theader,...
                QMAfn{fi}(1:min(opt.snspace(2)-1,numel(QMAfn{fi}))));
    Tline   = sprintf('%s%%%d.%df',Tline,opt.snspace(2),opt.snspace(3));
    Tline2  = sprintf('%s%%%d.%df',Tline2,opt.snspace(2),opt.snspace(3));
    Tavg    = sprintf('%s%%%d.%df',Tavg,opt.snspace(2),opt.snspace(3));
  end
  Cheader = [Cheader 'RMS'];
  Theader = sprintf(sprintf('%%s%%%ds',opt.snspace(2)),Theader,'RMS');
  Tline   = sprintf('%s%%%d.%df\n',Tline,opt.snspace(2),opt.snspace(3));
  Tline2  = sprintf('%s%%%d.%df\n',Tline2,opt.snspace(2),opt.snspace(3));
  Tavg    = sprintf('%s%%%d.%df\n',Tavg,opt.snspace(2),opt.snspace(3));
  
  
  

  
  
  % estimation part    
  switch action
    case {'p0','p#','c#','*#','p0+','p#+','c#+','*#+'}    
    % loop for multiple files 
      % return for empty input
      if isempty(Pp0) || (isempty(Pp0{1}) && numel(Pp0)<=1) 
        vbm_io_cprintf('com','No images for QA!\n'); 
        return
      end
      
      if opt.verb>1
        fprintf('\n%s\n\n%s\n%s\n', ...
          sprintf('VBM Preprocessing T1 Quality Assurance (%s):',...
          rev(2:end-2)), Theader,repmat('-',size(Theader)));  
      end

      qamat   = nan(numel(Po),numel(QMAfn));
      qamatm  = nan(numel(Po),numel(QMAfn));
      mqamatm = 9.9*ones(numel(Po),1);
    
      
      QAS = struct(); QAM = struct(); 
      
      for fi=1:numel(Pp0)
        try
          if exist(Po{fi},'file')
            Vo  = spm_vol(Po{fi});
          else
            error('vbm_tst_qa:noYo','No original image.');
          end
% tic   
          Yp0 = single(spm_read_vols(spm_vol(Pp0{fi})));
          if ~isempty(Pm{fi}) && exist(Pm{fi},'file')
            Ym  = single(spm_read_vols(spm_vol(Pm{fi})));
          else
            error('vbm_tst_qa:noYm','No corrected image.');
          end
% toc, tic   
          [QASfi,QAMfi,vbm_qa_warnings{fi}] = vbm_tst_qa('vbm12',Yp0,Vo,Ym,'',vbm_warnings,species,opt);

     
          QAS = vbm_io_updateStruct(QAS,QASfi,0,fi);
          QAM = vbm_io_updateStruct(QAM,QAMfi,0,fi);
        
          
          % color for the differen mark cases (opt.process)
          for fni=1:numel(QMAfn)
            qamat(fi,fni)  = QAS(fi).QM.(QMAfn{fni});
            qamatm(fi,fni) = QAM(fi).QM.(QMAfn{fni});
          end
          mqamatm(fi) = QAM(fi).QM.rms;
          mqamatm(fi) = max(0,min(9.5, mqamatm(fi)));
          
          
          % print the results for each scan 
          if opt.verb>1 
            if opt.orgval 
              vbm_io_cprintf(opt.MarkColor(max(1,round( mqamatm(fi,:)/9.5 * ...
                size(opt.MarkColor,1))),:),sprintf(Tline,fi,...
                QAS(fi).FD.fnames, ... spm_str_manip(QAS(fi).FD.file,['f' num2str(opt.snspace(1) - 14)]),...
                qamat(fi,:),max(1,min(6,mqamatm(fi)))));
            else
              vbm_io_cprintf(opt.MarkColor(max(1,round( mqamatm(fi,:)/9.5 * ...
                size(opt.MarkColor,1))),:),sprintf(Tline,fi,...
                QAS(fi).FD.fnames, ... spm_str_manip(QAS(fi).FD.file,['f' num2str(opt.snspace(1) - 14)]),...
                qamatm(fi,:),max(1,min(6,mqamatm(fi)))));
            end
          end
        catch  %#ok<CTCH> ... normal "catch err" does not work for MATLAB 2007a
          try %#ok<TRYNC>
            e = lasterror; %#ok<LERR> ... normal "catch err" does not work for MATLAB 2007a
         
            switch e.identifier
              case {'vbm_tst_qa:noYo','vbm_tst_qa:noYm','vbm_tst_qa:badSegmentation'}
                em = e.identifier;
              otherwise
                em = ['ERROR:\n' repmat(' ',1,10) e.message '\n'];
                for ei=1:numel(e.stack)
                  em = sprintf('%s%s%5d: %s\n',em,repmat(' ',1,10),...
                    e.stack(ei).line(end),e.stack(ei).name);
                end  
            end

            [pp,ff] = spm_fileparts(Po{fi});
            QAS(fi).FD.fnames = [spm_str_manip(pp,sprintf('k%d',floor( (opt.snspace(1)-19) /3) - 1)),'/',...
                                 spm_str_manip(ff,sprintf('k%d',(opt.snspace(1)-19) - floor((opt.snspace(1)-14)/3)))];
            vbm_io_cprintf(opt.MarkColor(end,:),sprintf(TlineE,fi,...
               QAS(fi).FD.fnames,[em '\n']));
%            spm_str_manip(Po{fi},['f' num2str(opt.snspace(1) - 14)]),em));
          end
        end
      end      
      
      
     
      % sort by mean mark
      % ----------------------------------------------------------------
      if opt.sortQATm && numel(Po)>1
        % sort matrix
        [smqamatm,smqamatmi] = sort(mqamatm,'ascend');
        sqamatm  = qamatm(smqamatmi,:);
        sqamat   = qamat(smqamatmi,:); 

        % print matrix
        if opt.verb>0
          fprintf('%s\n',repmat('-',size(Theader))); 
          for fi=1:numel(QAS)
            if opt.orgval 
              vbm_io_cprintf(opt.MarkColor(min(size(opt.MarkColor,1),...
                round( smqamatm(fi,:)/9.5 * ...
                size(opt.MarkColor,1))),:),sprintf(...
                Tline2,fi,sprintf('(%d)',smqamatmi(fi)),...
                QAS(smqamatmi(fi)).FD.fnames, ...
                ...spm_str_manip(QAS(smqamatmi(fi)).FD.file,['f' num2str(opt.snspace(1) - 14)]),...
                sqamat(fi,:),max(1,min(6,smqamatm(fi)))));
            else
              vbm_io_cprintf(opt.MarkColor(min(size(opt.MarkColor,1),...
                round( smqamatm(fi,:)/9.5 * ...
                size(opt.MarkColor,1))),:),sprintf(...
                Tline2,fi,sprintf('(%d)',smqamatmi(fi)),...
                QAS(smqamatmi(fi)).FD.fnames, ...
                ...spm_str_manip(QAS(smqamatmi(fi)).FD.file,['f' num2str(opt.snspace(1) - 14)]),...
                sqamatm(fi,:),smqamatm(fi)));
            end
          end
        end
      else
        %[smqamatm,smqamatmi] = sort(mqamatm,'ascend');
        %sqamatm  = qamatm(smqamatmi,:);
      end
      % print the results for each scan 
      if opt.verb>1 && numel(Pp0)>1
        fprintf('%s\n',repmat('-',size(Theader)));  
        if opt.orgval 
          fprintf(Tavg,'mean',vbm_stat_nanmean(qamat,1),mean(mqamatm,1));    %#ok<CTPCT>
          fprintf(Tavg,'std' , vbm_stat_nanstd(qamat,1), std(mqamatm,1));    %#ok<CTPCT>  
        else
          fprintf(Tavg,'mean',vbm_stat_nanmean(qamatm,1),mean(mqamatm,1));    %#ok<CTPCT>
          fprintf(Tavg,'std' , vbm_stat_nanstd(qamatm,1), std(mqamatm,1));    %#ok<CTPCT>  
        end 
        %fprintf('%s\n',repmat('-',size(Theader)));  
        %fprintf(Tavg,'mean',mean(qamat,1));  
        %fprintf(Tavg,'std', std(qamat,1));    
      end
      if opt.verb>0, fprintf('\n'); end


      
      % result tables (cell structures)
      % ----------------------------------------------------------------
      if nargout>2 && opt.write_csv
        QAT   = [Cheader(1:end-1); ... there is no mean for the original measures
                 Po               , num2cell(qamat); ...
                 'mean'           , num2cell(vbm_stat_nanmean(qamat,1)); ...
                 'std'            , num2cell( vbm_stat_nanstd(qamat,1))];
        QATm  = [Cheader; ...
                 Po               , num2cell(qamatm)          , ...
                                    num2cell(vbm_stat_nanmean(qamatm,2)); ...
                 'mean'           , num2cell(vbm_stat_nanmean(qamatm,1))  , ...
                                    num2cell(vbm_stat_nanmean(mqamatm,1)); ...
                 'std'            , num2cell( vbm_stat_nanstd(qamatm,1)), ...
                                    num2cell( vbm_stat_nanstd(mqamatm,1))];


        % write csv results
        % --------------------------------------------------------------
        if opt.write_csv
          pp = spm_fileparts(Pp0{1});
          vbm_io_csv(fullfile(pp,[opt.prefix num2str(numel(Vo),'%04d') ...
            'vbm_vol_qa_values.csv']),QAT);
          vbm_io_csv(fullfile(pp,[opt.prefix num2str(numel(Vo),'%04d') ...
            'vbm_vol_qa_marks.csv']),QATm);
        end
      end 
      
      if opt.verb>0
        fprintf('Quality Control for %d subject was done in %0.0fs\n', ...
          numel(Pp0),etime(clock,stime)); fprintf('\n');
      end
  
      
      
    case 'vbm12'
    % estimation of the measures for the single case    
% toc, tic        
      % file information
      % ----------------------------------------------------------------
      [pp,ff,ee] = spm_fileparts(Vo.fname);
      [QAS.FD.path,QAS.FD.file] = spm_fileparts(Vo.fname);
      QAS.FD.fname  = Vo.fname;
      QAS.FD.F      = Vo.fname; 
      QAS.FD.Fm     = fullfile(pp,['m'  ff ee]);
      QAS.FD.Fp0    = fullfile(pp,['p0' ff ee]);
      QAS.FD.fnames = [spm_str_manip(pp,sprintf('k%d',floor( max(opt.snspace(1)-19-ff,opt.snspace(1)-19)/3) - 1)),'/',...
                       spm_str_manip(ff,sprintf('k%d',(opt.snspace(1)-19) - floor((opt.snspace(1)-14)/3)))];
    

      % software information
      % ----------------------------------------------------------------
      A = ver;
      for i=1:length(A)
        if strcmp(A(i).Name,'Statistical Parametric Mapping')
          QAS.SW.spm    = A(i).Version; 
        end
        if strcmp(A(i).Name,'MATLAB'),
          QAS.SW.matlab = A(i).Version; 
        end
      end
      QAS.SW.vbm       = rev(6:10);
      QAS.SW.function  = which('vbm_vol_qa');
      QAS.SW.markdefs  = which('vbm_stat_marks');
      QAS.SW.qamethod  = action; 
      QAS.SW.date      = datestr(clock,'yyyymmdd-HHMMSS');
      QAS.SW.vbm_warnings = vbm_warnings;
      if exist('vbm','var');
        QAS.SW.vbm_defaults = vbm; 
      else
        QAS.SW.vbm_defaults = struct();
      end
      clear A

      
      %% inti, volumina, resolution, boundary box
      %  ---------------------------------------------------------------
      QAS.SW.vbm_qa_warnings = struct('identifier',{},'message',{});
      vx_vol = sqrt(sum(Vo.mat(1:3,1:3).^2));
      Yp0toC = @(Yp0,c) 1-min(1,abs(Yp0-c));
      
      %  volumina 
      QAS.SM.vol_abs_CGW = [prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),1)), ... CSF
                            prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),2)), ... GM 
                            prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),3)), ... WM
                            prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),4))];  % WMH
      QAS.SM.vol_TIV     =  sum(QAS.SM.vol_abs_CGW); 
      QAS.SM.vol_rel_CGW =  QAS.SM.vol_abs_CGW ./ QAS.SM.vol_TIV;
      
      %  resolution 
      QAS.QM.res_vx_vol    = vx_vol;
      QAS.QM.res_isotropy  = max(vx_vol)./min(vx_vol);
      QAS.QM.res_vol       = prod(abs(vx_vol));
      QAS.QM.res_RMS       = mean(vx_vol.^2).^0.5;
      QAS.QM.res_MVR       = mean(vx_vol);
      
      % boundary box - brain tissue next to image boundary
      bbth = round(2/mean(vx_vol)); M = true(size(Yp0));
      M(bbth:end-bbth,bbth:end-bbth,bbth:end-bbth) = 0;
      QAS.QM.res_BB = sum(Yp0(:)>1.25 & M(:))*QAS.QM.res_vol; 

      % check segmentation
      spec = species; for ai=num2str(0:9); spec = strrep(spec,ai,''); end; 
      bvol = species; for ai=char(65:122); bvol = strrep(bvol,ai,''); end; bvol = str2double(bvol);
      
      subvol = [sum(Yp0(:)>2.5 & Yp0(:)<3.1)*prod(vx_vol)/1000,... 
                sum(Yp0(:)>1.5 & Yp0(:)<2.5)*prod(vx_vol)/1000,...
                sum(Yp0(:)>0.5 & Yp0(:)<1.5)*prod(vx_vol)/1000]; 
      
      if isempty(bvol) 
        switch spec
          case 'human'
            bvol = 1400; 
          otherwise
            warning('vbm_tst_qa:species',sprintf('Unknown species %s (C=%0.0f,G=%0.0f,W=%0.0f).',species,subvol)); %#ok<SPWRN>
        end
      end
      if  sum(subvol)<bvol/3 || sum(subvol)>bvol*3
        warning('vbm_tst_qa:badSegmentation',sprintf('Bad %s segmentation (C=%0.0f,G=%0.0f,W=%0.0f).',species,subvol)) %#ok<SPWRN>
      end

      
% toc, tic      
      %  ---------------------------------------------------------------
      %  estimate QA
      %  ---------------------------------------------------------------
      %  reduce resolution
      [Yo,Ym,Yp0,BB]   = vbm_vol_resize({Yo,Ym,Yp0},'reduceBrain',vx_vol,5,Yp0>1.2);
      [Yo,Ym,Yp0,resr] = vbm_vol_resize({Yo,Ym,Yp0},'reduceV',vx_vol,0.5,32,'meanm'); vx_vol=resr.vx_volr;
   
      
      %% bias correction for Yo data 
      %  ---------------------------------------------------------------
      preproc = [1 1 1];
      if preproc(1)==2
        [Yor,Ymr,resT3] = vbm_vol_resize({Yo.*(Yp0>2.),Ym.*(Yp0>0)},'reduceV',vx_vol,4,32,'max');
        Yp0r = vbm_vol_resize(Yp0,'reduceV',vx_vol,4,32,'meanm');
        mf  = mean(Yor(Yp0r(:)>2.9)) / mean(Ymr(Yp0r(:)>2.9));
        Yir = Yor./max(eps,Ymr .* mf); Yir(Yir>2 | Yp0r<2.9)=0; 
        for xi=1:1, Yir = vbm_vol_localstat(Yir,Yir>0,2,1); end
        Yii = vbm_vol_approx(Yir,'nh',4,2); Yii = vbm_vol_smooth3X(Yii,4); Yii(Yir>0) = Yir(Yir>0);
        Yi  = vbm_vol_resize(vbm_vol_smooth3X(Yii,4),'dereduceV',resT3);
        Ymi = Yo ./ Yi;
        clear Yor Ymr Yp0r Yir mf;
      elseif preproc(1)==1
        [Yor,Ymr,resT3] = vbm_vol_resize({Yo.*(Yp0>2.),Ym.*(Yp0>0)},'reduceV',vx_vol,4,32,'max');
        Yp0r = vbm_vol_resize(Yp0,'reduceV',vx_vol,4,32,'meanm');
        mf  = mean(Yor(Yp0r(:)>2.9)) / mean(Ymr(Yp0r(:)>2.9));
        Yir = Yor./max(eps,Ymr .* mf); Yir(Yir>2 | Yp0r<2.9)=0; 
        for xi=1:1, Yir = vbm_vol_localstat(Yir,Yir>0,2,1); end
        Yii = vbm_vol_approx(Yir,'nh',4,2); Yii = vbm_vol_smooth3X(Yii,4); Yii(Yir>0) = Yir(Yir>0);
        Yi  = vbm_vol_resize(vbm_vol_smooth3X(Yii,4),'dereduceV',resT3);
        Ymi = Yo ./ Yi;
        clear Yor Ymr Yp0r Yir mf;
      else
        Ymi = Yo;
      end
      Ym = Ymi; % replace Ymi by Ym later
      
    
      
      %% brain extraction
      %  ---------------------------------------------------------------
      if preproc(2)
        T3th = tissue_mn(Ym,Yp0,vx_vol,2);
        [Yp0r,Ymr,resT3] = vbm_vol_resize({Yp0,Ym},'reduceV',vx_vol,2.5,32,'meanm');    
        Ymr  = vbm_vol_median3(Ymr,Yp0r>0.5);
        Yb   = single(vbm_vol_morph(Yp0r>2.25 | (Yp0r>0 & Ymr>mean(T3th(2:3)) & Ymr<T3th(3)*1.5),'lo',1)); 
        % region-growing
        Yb(Ymr<T3th(1) | Ymr>T3th(3)*1.2)=nan;
        [Yb1,YD] = vbm_vol_downcut(Yb,Ymr/T3th(3),0.01); Yb(isnan(Yb))=0; Yb(YD<400)=1; 
        Yb(smooth3(Yb)<0.5)=0; 
        Yb(Ymr<T3th(1)*0.8)=nan;
        [Yb1,YD] = vbm_vol_downcut(Yb,Ymr/T3th(3),0.00); Yb(isnan(Yb))=0; Yb(YD<100)=1; 
        Yb(smooth3(Yb)<0.5)=0; 
        % ventrile closing
        [Ybr,Ymr,resT2] = vbm_vol_resize({Yb>0,Ymr/T3th(3)},'reduceV',resT3.vx_volr,4,32); % 4 mm
        Ybr = Ybr | (Ymr<0.8 & vbm_vol_morph(Ybr,'lc',3)); % large ventricle closing
        Ybr = vbm_vol_morph(Ybr,'lc',2);                   % standard closing
        Ybb = vbm_vol_morph(Ybr,'e',2);                    % save inner tissue
        % back to original resolution
        Yb  = vbm_vol_resize(Ybr,'dereduceV',resT2)>0.5; 
        Yb  = vbm_vol_resize(vbm_vol_smooth3X(Yb,1),'dereduceV',resT3);
        Ybb = vbm_vol_resize(Ybb,'dereduceV',resT2)>0.5; 
        Ybb = vbm_vol_resize(vbm_vol_smooth3X(Ybb,1),'dereduceV',resT3);
        Ybb = Ybb>0.5; 
        Yb  = Yb>0.5;
        % apply new brainmask 
        Yp0(Yb==0)=0;
        clear Ybr
      else
        T3th = tissue_mn(Ym,Yp0,vx_vol,2);
        Yb  = Yp0>0;
        [Ybr,resT2] = vbm_vol_resize(Yb,'reduceV',vx_vol,4,32);
        Ybb = vbm_vol_morph(Ybr,'e',4);
        Ybb = vbm_vol_resize(Ybb,'dereduceV',resT2)>0.5; 
        clear Ybr;
      end
      
      %[Yo,Ym,Yp0,Yb,Ybb,Ymi,BB]   = vbm_vol_resize({Yo,Ym,Yp0,Yb,Ybb,Ymi},'reduceBrain',vx_vol,2,Yp0>1.2);

      
      %% AMAP segmentation
      %  ---------------------------------------------------------------
      % AmapMex(Ym,Yp0,tcls,iter,psize,pvecls,kmeans,mrf,vx_vol,biasiter,biasfwhm
      if preproc(3)
        [Ymir,Yp0r,Ybr,resT3] = vbm_vol_resize({Ymi,Yp0,Yb},'reduceV',vx_vol,2.5,32,'meanm');
        Ymir = double(Ymir);
        Ypxr = vbm_pre_gintnorm(Ymir.*Ybr,[0,T3th])*3; Yp0r(Yp0r==0) = Ypxr(Yp0r==0); clear Ypxr
        Yp0r = vbm_vol_ctype(min(3,Yp0r)); % double(noise)
        prob = AmapMex(Ymir,Yp0r,3,1,16,5,0,0.3,resT3.vx_vol,4,60);
        Yp0r = single(prob(:,:,:,2))/255*2 + single(prob(:,:,:,3))/255*3 + single(prob(:,:,:,1))/255; 
        Yp0  = vbm_vol_resize(Yp0r,'dereduceV',resT3);
      end
      
      
     
      %% (relative) average tissue intensity of each class
      %  ---------------------------------------------------------------
      
      % estimate background
      [Yosr,resYbg] = vbm_vol_resize(Ymi,'reduceV',vx_vol,3,32,'meanm'); 
      weighting = T3th(3)>T3th(1); if weighting, Tw2b=0.2; else Tw2b=1; end
      warning 'off' 'MATLAB:vbm_vol_morph:NoObject'
      BGCth = min(T3th .* [1 1 Tw2b])/2;
      Ybgr  = vbm_vol_morph(vbm_vol_morph(Yosr<BGCth,'lc',1),'e',2/mean(resYbg.vx_volr)) & ~isnan(Yosr);
      Ybg   = vbm_vol_resize(Ybgr,'dereduceV',resYbg)>0.5; clear Yosr Ybgr;
      if sum(Ybg(:))<32, Ybg = vbm_vol_morph(Yo<BGCth,'lc',1) & ~isnan(Yo); end
      warning 'on'  'MATLAB:vbm_vol_morph:NoObject'
      
      [Ymir,Ybgr] = vbm_vol_resize({Ymi,Ybg},'reduceV',vx_vol,3,32,'meanm'); 
      Ymir  = round(Ymir*100)/100;
      BGth  = vbm_stat_nanmedian(Ymir(Ybgr(:)>0.9));   
      clear Ymir Ybgr;
      
      tp=1;
      if tp==1
        T3th = tissue_mn(Ym,Yp0.*Ybb,vx_vol,4);
      elseif tp==2
        T3th = tissue_mn(Ym,Yp0.*Ybb,vx_vol,4,[2 3 2;1 2 2]); %[2 3 2;1 2 2]
      else
        T3th = tissue_mn(Ym,Yp0.*Ybb,vx_vol,4)/2 + tissue_mn(Ym,Yp0.*Ybb,vx_vol,4,[2 3 2;1 2 2])/2;
      end
      CSFth = T3th(1); GMth = T3th(2); WMth = T3th(3);

      QAS.QM.tissue_mn  = ([BGth CSFth GMth WMth]);
      QAS.QM.tissue_mnr = QAS.QM.tissue_mn ./ (max([WMth,GMth]));
      if WMth>GMth
        QAS.QM.tissue_weighting = 'T1';
      elseif WMth<GMth && GMth<CSFth
        QAS.QM.tissue_weighting = 'inverse';
      end
      
      % (relative) standard deviation of each class
      QAS.QM.tissue_std(1) = vbm_stat_nanstd( Yo(Ybg(:)) );
      for ci=3:4
        QAS.QM.tissue_std(ci) = vbm_stat_nanstd(Yo(Yp0toC(Yp0(:),ci-1)>0.5 & ~isinf(Yp0(:))));
      end
      QAS.QM.tissue_stdr = QAS.QM.tissue_std ./ (WMth-BGth);
     
      % (relative) mininum tissue contrast ( CSF-GM-WM ) 
      QAS.QM.contrast  = min(abs(diff(QAS.QM.tissue_mn(2:4)))); 
      QAS.QM.contrastr = min(abs(diff(QAS.QM.tissue_mn(2:4)))) ./ (max([WMth,GMth]));
   
      % new segmetn volumina 
      QAS.QM.vol_abs_CGW = [prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),1)), ... CSF
                            prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),2)), ... GM 
                            prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),3)), ... WM
                            prod(vx_vol)/1000 .* sum(Yp0toC(Yp0(:),4))];  % WMH
      QAS.QM.vol_TIV     =  prod(vx_vol)/1000 .* sum(Yb(:)); 
      QAS.QM.vol_rel_CGW =  QAS.SM.vol_abs_CGW ./ QAS.SM.vol_TIV;
      
      
       %% noise estimation (original (bias corrected) image)
      Yn = (Ymi./T3th(3)) .* (Yp0toC(Yp0,3)>0.9) .* (Ymi>(T3th(3) - QAS.QM.tissue_std(3))) + ...
           (Ymi./T3th(3) - T3th(1)/T3th(3) + 1) .* (Yp0toC(Yp0,1)>0.9 & Ybb);
      [Yn,Yr] = vbm_vol_resize({Yn,Yn>0},'reduceV',1,2,16,'meanm'); %Yr = Yr>0.5;
      %Yn  = Yn - mean(Yn(Yr(:)));
      ncr = 1:4; noiser = zeros(size(ncr));  
      for si=1:numel(ncr)
        %Yns = Yn+0; spm_smooth(Yns,Yns,ncr(si)./(vx_vol*2)); 
        %Yns = Yns .* max(1,log2(prod(ncr(si)./(vx_vol*2))));
        Yn = vbm_vol_localstat(Yn,Yr,1,1)*1.25;
        %Yn = Yn .* (log(prod(ncr(si)./(vx_vol/2))));
        %Yn = vbm_vol_localstat(Yn,Yr,1,4);
        Yg = vbm_vol_grad(Yn,vx_vol./2);
        
        noiser(si) = vbm_stat_nanmean(Yg(Yg>0));
      end
      QAS.QM.NCR = std(Ymi(Yp0toC(Yp0(:),3)>0.9)/T3th(3)) ./ QAS.QM.contrastr;
     % QAS.QM.NCR = std(Ymi(Ybg(:))/T3th(3))*3 ./ QAS.QM.contrastr;
      QAS.QM.NCR = QAS.QM.NCR .* ( 1+log(prod(vx_vol)) ); 
      QAS.QM.CNR = 1 / QAS.QM.NCR; 
      
      %% noise estimation (original (bias corrected) image)
      %{
      ncr = 2:4; noiser = zeros(size(ncr));
      for ri=1:numel(ncr);
        Ygr = vbm_vol_resize((Ymi ./ T3th(3)) .* (Yp0>2.9),'reduceV',vx_vol,max(1,vx_vol)*ncr(ri),16,'meanm');
        Ygr = vbm_vol_grad(Ygr,vx_vol); noiser(ri) = vbm_stat_nanmean(Ygr(Ygr>0));  
      end
      QAS.QM.noiseo = mean(noiser).*(QAS.QM.res_vol)^(1/3);  
       %}
      
      ncr = 3:0.25:4; noiser = zeros(size(ncr)); 
      Ywm = vbm_vol_morph(vbm_vol_morph(Yp0>2.9,'e',1) & Ymi>(T3th(3)*0.8+0.2*T3th(2)),'c');
      Ymis=Ymi; for xi=1:1, Ymis = vbm_vol_localstat(Ymis,Ywm,1,1); end
%       Ygr = vbm_vol_resize((Ymis ./ T3th(3)) .* (Ywm),'reduceV',vx_vol,4,16,'meanm');
%       Ygr = vbm_vol_localstat(Ygr,Ygr>0,1,1);
%       Ygr = vbm_vol_grad(Ygr,[1 1 1]); %mean([resG.vx_vol;1./resG.vx_red;resG.vx_volr])); 
%       noise1 = vbm_stat_nanmedian(Ygr(Ygr>0));
%       Ywm = vbm_vol_morph(Yp0>2.9,'e',1) & Ymi>(T3th(3) - 2*noise1);
      for ri=1:numel(ncr);
        [Ygr,resG] = vbm_vol_resize((Ymi ./ T3th(3)) .* (Ywm),'reduceV',vx_vol,ncr(ri),16,'meanm');
        Ygr = vbm_vol_localstat(Ygr,Ygr>0,1,1);
        Ygr = vbm_vol_grad(Ygr,[1 1 1]); %resG.vx_volr/max(resG.vx_volr)); %mean([resG.vx_vol;1./resG.vx_red;resG.vx_volr])); 
        noiser(ri) = vbm_stat_nanmedian(Ygr(Ygr>0)); %*prod(resG.vx_volr)^(1/3) / 4;  
      end
      QAS.QM.noiser = noiser;
      noise = max(0,mean(noiser))*2.*(QAS.QM.res_vol)^(1/3);    
      
      
      
      %% noise estimation (original (bias corrected) image)
    
      
      rms = 1; 
      % WM variance only in one direction to avoid WMHs!
      Yos1 = Ymi .* vbm_vol_morph(Ywm & Ymi>(vbm_stat_nanmedian(Ymi(Ywm(:))) - 2*std(Ymi(Ywm(:)))),'c');
      for xi=1:1, Yos1 = vbm_vol_localstat(Yos1,Yos1>0,1,1); end
      [Yos2,res2] = vbm_vol_resize(Yos1,'reduceV',1,4,16,'meanm'); Yos2 = vbm_vol_localstat(Yos2,Yos2>0,1,1)*2.5;
      [Yos3,res3] = vbm_vol_resize(Yos1,'reduceV',1,3,16,'meanm'); Yos3 = vbm_vol_localstat(Yos3,Yos3>0,1,1)*2.5; 
      NCww = sum(Yos1(:)>0);
      QAS.QM.NCRw2 = estimateNoiseLevel(Yos2,Yos2>0,1,rms);% * mean(res2.vx_vol)/mean(res2.vx_volr); 
      QAS.QM.NCRw3 = estimateNoiseLevel(Yos3,Yos3>0,1,rms);% * mean(res3.vx_vol)/mean(res3.vx_volr);
      NCRw = mean([...estimateNoiseLevel(Yos0,YM0,4,rms), ...
                   QAS.QM.NCRw2, ...max(GMth,WMth)
                   QAS.QM.NCRw3]) / (max(GMth,WMth)) / QAS.QM.contrastr; 
      clear Yos0 Yos1 Yos2 YM0 YM1 YM2;
      QAS.QM.NCRw = NCRw;
     
      
      % CSF variance of large ventricle
      Ygm = Yp0toC(Yp0,2)>0.5;
      if vbm_stat_nanmedian(Yo(Ygm)) < vbm_stat_nanmedian(Yo(Ywm)) % T1 Yg<gth &
        Ycm = Yp0toC(Yp0,1)>0.9 & Yo<mean(T3th(1:2)) & Yo>T3th(1)/2 & Ybb & ~Ywm & ~Ygm & ... 
          (~vbm_vol_morph(Yp0<0.5 | Yp0>1.5 | Ymi>mean(T3th(1:2)) | Ymi<mean(T3th(1)/2),'d',1/mean(vx_vol)));
      else
        Ycm = Yp0toC(Yp0,1)>0.85 & Ybb & ~Ywm & ~Ygm;
      end
     
      Ycmo = vbm_vol_morph(Ycm,'o',2/mean(vx_vol)); Ycmo = smooth3(Ycmo)>0.5;
      Yos1 = Ymi .* (Ycmo & Ymi>(vbm_stat_nanmedian(Ymi(Ycmo(:))) + 2*std(Ymi(Ycmo(:)))));
      NCwc = sum(Yos1(:)>0);
      % for typical T2 images we have to much signal in the CSF and
      % can't use it for noise estimation!
      if CSFth>GMth, NCwc = 0; end
      if NCwc>20
        [Yos2,res2] = vbm_vol_resize(Yos1,'reduceV',1,4,16,'meanm'); Yos2 = vbm_vol_localstat(Yos2,Yos2>0,1,1)*2.5;
        [Yos3,res3] = vbm_vol_resize(Yos1,'reduceV',1,3,16,'meanm'); Yos3 = vbm_vol_localstat(Yos3,Yos3>0,1,1)*2.5; 
        QAS.QM.NCRc2 = estimateNoiseLevel(Yos2,Yos2>0,2,rms);% * prod(res2.vx_vol)/prod(res2.vx_volr);
        QAS.QM.NCRc3 = estimateNoiseLevel(Yos3,Yos3>0,3,rms);% * prod(res3.vx_vol)/prod(res3.vx_volr);
        NCRc = mean([...estimateNoiseLevel(Yos0,YM0,4,rms), ...
                     QAS.QM.NCRc2, ...
                     QAS.QM.NCRc3]) / (max(GMth,WMth))  / QAS.QM.contrastr; 
        clear Yos0 Yos1 Yos2 YM0 YM1 YM2;
      else
        NCRc = 0;
        NCwc = 0;
      end
      QAS.QM.NCRc = NCRc;
      % averaging
      QAS.QM.NCR = (NCRw*NCww + NCRc*NCwc)/(NCww+NCwc);
      QAS.QM.NCR = QAS.QM.NCR / (1-QAS.QM.NCR) /QAS.QM.contrastr ; % signal-nosignal change & contrast 
      QAS.QM.NCR = QAS.QM.NCR * ((QAS.QM.res_vol)^(1/3)); % volume change in bwp

     % QAS.QM.NCR = noise / QAS.QM.contrastr * 3; %/ (1-noise/4)
     % QAS.QM.CNR = 1 / QAS.QM.NCR;  
     
      QAS.QM.noise   = noise;
      QAS.QM.noisec1 = noise / (1-noise/4);
      %}
      
      
      
      
    
      %% Bias/Inhomogeneity (original image with smoothed WM segment)
      Yosm = Yo .* (Yp0>2.5); 
      for xi=1:2, Yosm = vbm_vol_localstat(Yosm,Yosm>0,1,1); end
      Yosm = vbm_vol_resize(Yosm,'reduceV',vx_vol,2,32,'max');  % denoising
      for xi=1:1, Yosm = vbm_vol_localstat(Yosm,Yosm>0,2,3); end
      Yosm = vbm_vol_resize(Yosm,'reduceV',vx_vol/2,2,32,'meanm');  % denoising
      for xi=1:1, Yosm = vbm_vol_localstat(Yosm,Yosm>0,2,1); end
      QAS.QM.ICR  = vbm_stat_nanstd( Yosm(Yosm(:)>0)/ T3th(3));
      QAS.QM.ICR  = QAS.QM.ICR / (1-QAS.QM.ICR) / QAS.QM.contrastr;
      QAS.QM.CIR  = 1 / QAS.QM.ICR;

      %%
      clear Yo;

 %fprintf('%s: %4.0f %4.0f %4.0f %4.0f - %0.3f - %0.3f\n',pp,QAS.QM.tissue_mn, QAS.QM.NCR * QAS.QM.contrast,QAS.QM.contrast);

      % CJVs
%       QAS.QM.CJV2  = ( vbm_stat_nanstd(Yo(Ygm(:))) +  vbm_stat_nanstd(Yo(Ywm(:)))) ./ ...
%                      (vbm_stat_nanmean(Yo(Ygm(:))) + vbm_stat_nanmean(Yo(Ywm(:))));
%       QAS.QM.CJV   = ( vbm_stat_nanstd(Yo(Yp0toC(Yp0(:),2)>0.5)) +  vbm_stat_nanstd(Yo(Yp0toC(Yp0(:),3)>0.5))) ./ ...
%                      (vbm_stat_nanmean(Yo(Yp0toC(Yp0(:),2)>0.5)) + vbm_stat_nanmean(Yo(Yp0toC(Yp0(:),3)>0.5)));
%       QAS.QM.CJVm2 = ( vbm_stat_nanstd(Ym(Ygm(:))) +  vbm_stat_nanstd(Ym(Ywm(:)))) ./ ...
%                      (vbm_stat_nanmean(Ym(Ygm(:))) + vbm_stat_nanmean(Ym(Ywm(:))));
%       QAS.QM.CJVm  = ( vbm_stat_nanstd(Ym(Yp0toC(Yp0(:),2)>0.5)) +  vbm_stat_nanstd(Ym(Yp0toC(Yp0(:),3)>0.5))) ./ ...
%                      (vbm_stat_nanmean(Ym(Yp0toC(Yp0(:),2)>0.5)) + vbm_stat_nanmean(Ym(Yp0toC(Yp0(:),3)>0.5)));      
% toc          
      %% STC: subject template conformity 
      %  -------------------------------------------------------------
      Fwrp0 = fullfile(pp,['wrp0' ff ee]);
      if opt.calc_STC && exist(Fwrp0,'file')
        Ywrp0 = single(spm_read_vols(spm_vol(Fwrp0)));
        [QAS.QM.STC,Yt,QAS.SW.STCtype] = vbm_qa_calcSTC(Ywrp0,Vm,[],...
          opt.output.te,res); 
        clear Yt;
      else
        QAS.QM.STC     = nan;
        QAS.SW.STCtype = 'notestimated';
      end



      %% MJD: jabobian determinant in template space
      %  -------------------------------------------------------------
      Fjac = fullfile(pp,['jac_wrp1' ff ee]);
      if opt.calc_MJD && exist(Fjac,'file')
        Yjac = single(spm_read_vols(spm_vol(Fjac)));
        if exist(Fwrp0,'file')
          Ywrp0 = single(spm_read_vols(spm_vol(Fwrp0)));
          QAS.QM.MJD = std(Yjac(Ywrp0(:)>0.5));
          QAS.SW.MJDtype = 'Ywrp0 masked';
        else
          Ywrp0 = vbm_vol_smooth3X(vbm_vol_morph(Yjac>0.9 & Yjac<1.1,...
            'lo',2),5)<0.5;
          QAS.QM.MJD = std(Yjac(Ywrp0(:)>0.5));
          QAS.SW.MJDtype = 'own mask';
        end
      else
        QAS.QM.MJD = nan;
      end  


      %% PCM: preprocessing change map (8 seconds)
      %  ---------------------------------------------------------------
      if opt.calc_MPC  &&  GMth<WMth % T1
        
          %% intensity scalling  
          if 1
            %~(vbm_stat_nanmedian(Ym(Yp0>2.5))>0.9 &&  vbm_stat_nanmedian(Ym(Yp0>2.5))<1.1)
            Ybcx = max(0,(Yo - BGth) / max(eps,max([WMth,GMth]) - BGth));
            Yi   = vbm_pre_gintnorm(Ybcx,QAS.QM.tissue_mnr);
            %Yis  = Yi.*(Yp0>0);  sanlmMex_noopenmp(Yis,3,1); Yi(Yp0>0) = Yis(Yp0>0); clear Yis;
            %Yi   = vbm_vol_median3(Yi,Yp0>0,Yp0>0);
            %Yi  = smooth3(Yi);
    %         for ci=1:3
    %           Yis = vbm_vol_localstat(Yi,Yp0toC(Yp0,ci)>0.9,1,1); 
    %           Yi(Yp0toC(Yp0,ci)>0.9) = Yis(Yp0toC(Yp0,ci)>0.9); clear Yis;
    %         end
            clear Ybcx;
          else
            Yi = Ym; 
          end

        % set transformations to subject space for export (20 seconds!)
        if opt.calc_MPC && any(cell2mat(struct2cell(opt.output.pc))) && ...
           (exist(vbm12mat,'file') ||  exist(vbm8mat,'file')) && opt.process~=0 
          tpm = spm_load_priors8(res.tpm);
          d  = res.image(1).dim(1:3);
          [x1,x2] = ndgrid(1:d(1),1:d(2),1);
          x3 = 1:d(3);
          M = tpm.M\res.Affine*res.image(1).mat;

          Yy = zeros([size(Yp0),3],'single');
          for z=1:length(x3),
            prm     = [3 3 3 0 0 0];
            Coef    = cell(1,3);
            Coef{1} = spm_bsplinc(res.Twarp(:,:,:,1),prm);
            Coef{2} = spm_bsplinc(res.Twarp(:,:,:,2),prm);snspace
            Coef{3} = spm_bsplinc(res.Twarp(:,:,:,3),prm);
            [t1,t2,t3] = defs(Coef,z,res.MT,prm,x1,x2,x3,M);       

            Yy(:,:,z,1) = t1;
            Yy(:,:,z,2) = t2;
            Yy(:,:,z,3) = t3;
          end
          clear d x1 x2 x3 tpm M prm Coef t1 t2 t3;
          trans.atlas.Yy = Yy;
          res.image(1).mat;
        end

        % estimate MPC
        YM  = Yp0toC(Yp0,3)>0.95 | Yp0toC(Yp0,2)>0.95 | (Yp0toC(Yp0,1)>0.95 & Yi<1.5/3 & Yi>0.5/3); 
        %YM  = (Yp0>1.5 & Yp0<3.05 & Yg<0.3) | (Yp0toC(Yp0,1)>0.9 & Yi<1.5/3 & Yi>0.5/3 & Yg<0.3);
        Ypc = zeros(size(Yp0),'single'); Ypc(YM) = abs(3*min(7/6,Yi(YM)) - Yp0(YM));
        YM  = Yp0>0 & ~YM; Yc = vbm_vol_localstat(Yi,YM,2,1);
        Ypc(YM) = abs(Yi(YM) - Yc(YM))*3; 
        QAS.QM.MPC = sum(Ypc(:)) ./ sum((Yp0(:)>1 & Yp0(:)<3.1)); 
        if any(cell2mat(struct2cell(opt.output.pc)))
          Ypc = vbm_vol_resize(Ypc,'dereduceBrain',BB); 
          vbm_io_writenii(spm_vol(res.image(1).fname),Ypc,'pcm', ...
              ['vbm12 - preprocessing change/correction map ' ...
               'of the normalized T1 image (m*.nii)'], ...
              'uint8',[0,1/255],opt.output.pc,trans);
        end
        clear Ypc trans
      else
        QAS.QM.MPC = nan;
      end
  
    %% marks
    QAM = vbm_stat_marks('eval',1,QAS,opt.method);

    % export 
    if opt.write_xml
      vbm_io_xml(fullfile(pp,[opt.prefix ff '.xml']),struct('QAS',QAS,'QAM',QAM'),'write+');
    end
    
    clear Yi Ym Yo Yo Yo
    clear Ywm Ygm Ycsf Ybg
     
  end

  
  if nargout>3 && ~strcmp(action,'vbm12'), varargout{4} = Pp0; end
  if nargout>2, varargout{3} = vbm_qa_warnings; end
  if nargout>1, varargout{2} = QAM; end
  if nargout>0, varargout{1} = QAS; end 

end
%=======================================================================
function T3th = tissue_mn(Ym,Yp0,vx_vol,res,Tkc)
  if ~exist('vx_vol','var'), vx_vol=[1 1 1]; end
  if ~exist('res','var'),    res=4; end
  if ~exist('Tkc','var'),    type='median'; else type='means'; end

  p0toC = @(Yp0,c) 1-min(1,abs(Yp0-c));
   
  T3th = zeros(1,3);
  if 0
    for i=1:3
      [Ymr,Yp0r] = vbm_vol_resize({Ym,Yp0},'reduceV',vx_vol,max(vx_vol)*res,16,'meanm');    

      switch type
        case 'median'
           Ymr = round(Ymr*1000)/1000;
           T3th(i) = vbm_stat_nanmedian(Ymr(p0toC(Yp0,i)>0.8));
        case 'means'
           means   = kmeans3D(Ymr(p0toC(Yp0,i)>0.8),Tkc(1,i)); 
           T3th(i) = means(Tkc(2,i));
      end
    end
  else
    for i=1:3
      Ymr = vbm_vol_resize(Ym .* (p0toC(Yp0,i)>0.8),'reduceV',vx_vol,max(vx_vol)*res,16,'meanm');    

      switch type
        case 'median'
           Ymr = round(Ymr*1000)/1000;
           T3th(i) = vbm_stat_nanmedian(Ymr(Ymr>0));
        case 'means'
           means   = kmeans3D(Ymr(Ymr>0),Tkc(1,i)); 
           T3th(i) = means(Tkc(2,i));
      end
    end
  end
end
function def=defaults
  % default parameter 
  def.verb       = 2;         % verbose level    [ 0=nothing | 1=points | 2*=results ]
  def.write_csv  = 2;         % final cms-file [ 0=dont write |1=write | 2=overwrite ]
  def.write_xml  = 1;         % images base xml-file
  def.sortQATm   = 1;         % sort QATm output
  def.orgval     = 0;         % original QAM results (no marks)
  def.avgfactor  = 2;         % 
  def.prefix     = 'vbm_';    % intensity scaled  image
  def.mprefix    = 'm';       % prefix of the preprocessed image
  def.process    = 3;         % used image [ 0=T1 | 1=mT1 | 2=avg | 3=both ] 
  def.calc_MPC   = 0;
  def.calc_STC   = 0;
  def.calc_MJD   = 0;
  def.method     = 'spm';
  def.snspace    = [70,7,3];
  def.nogui      = exist('XT','var');
  def.output.te  = struct('native',cg_vbm_get_defaults('output.te.native'), ...
                          'warped',cg_vbm_get_defaults('output.te.warped'), ...
                          'dartel',cg_vbm_get_defaults('output.te.dartel'));
  def.output.pc  = struct('native',cg_vbm_get_defaults('output.pc.native'), ...
                          'warped',cg_vbm_get_defaults('output.pc.warped'), ...
                          'dartel',cg_vbm_get_defaults('output.pc.dartel'));
  def.MarkColor = vbm_io_colormaps('marks+',40); 
end

function noise = estimateNoiseLevel(Ym,YM,r,rms,vx_vol)
% ----------------------------------------------------------------------
% noise estimation within Ym and YM.
% ----------------------------------------------------------------------
  if ~exist('vx_vol','var');
    vx_vol=[1 1 1]; 
  end
  if ~exist('r','var');
    r = 1;
  else
    r = min(10,max(max(vx_vol),r));
  end
  if ~exist('rms','var')
    rms = 1;
  end
  
  Ysd   = vbm_vol_localstat(single(Ym),YM,r,4);
  noise = vbm_stat_nanstat1d(Ysd(YM).^rms,'median').^(1/rms); 
end
%=======================================================================
function [x1,y1,z1] = defs(sol,z,MT,prm,x0,y0,z0,M)
  iMT = inv(MT);
  x1  = x0*iMT(1,1)+iMT(1,4);
  y1  = y0*iMT(2,2)+iMT(2,4);
  z1  = (z0(z)*iMT(3,3)+iMT(3,4))*ones(size(x1));
  x1a = x0    + spm_bsplins(sol{1},x1,y1,z1,prm);
  y1a = y0    + spm_bsplins(sol{2},x1,y1,z1,prm);
  z1a = z0(z) + spm_bsplins(sol{3},x1,y1,z1,prm);
  x1  = M(1,1)*x1a + M(1,2)*y1a + M(1,3)*z1a + M(1,4);
  y1  = M(2,1)*x1a + M(2,2)*y1a + M(2,3)*z1a + M(2,4);
  z1  = M(3,1)*x1a + M(3,2)*y1a + M(3,3)*z1a + M(3,4);
end
%=======================================================================
function Ym = vbm_pre_gintnorm(Ysrc,T3th)
% ----------------------------------------------------------------------
% Global intensity normalization based on tissue thresholds T3th with 
% [background CSF GM WM] values.
% ----------------------------------------------------------------------

  T3th2 = [T3th ...
           T3th(end)+diff(T3th([1,numel(T3th)])/2) ...
           max(T3th(end)+diff(T3th([1,numel(T3th)])/2) , ...
           max(Ysrc(~isnan(Ysrc(:)) & ~isinf(Ysrc(:))))) ];
  T3thx = [0 1/3 2.0/3 3/3 4/3 4];
  clear Ysrcs; 
  
  %% intensity scalling
  isc = 1;
  T3th2 = interp1(T3th2,1:1/isc:numel(T3th2),'spline');  %pchip');
  T3thx = interp1(T3thx,1:1/isc:numel(T3thx),'spline'); %pchip');
  
  Ym = Ysrc;
  for i=2:numel(T3th2)
    M = Ysrc>T3th2(i-1) & Ysrc<=T3th2(i);
    Ym(M(:)) = T3thx(i-1) + (Ysrc(M(:)) - T3th2(i-1))/...
      diff(T3th2(i-1:i))*diff(T3thx(i-1:i));
  end
  M  = Ysrc>=T3th2(end); 
  Ym(M(:)) = numel(T3th2)/isc/6 + (Ysrc(M(:)) - T3th2(i))/...
    diff(T3th2(end-1:end))*diff(T3thx(i-1:i));    
  M  = Ysrc<T3th2(1); 
  Ym(M(:)) = 0; 

end

%=======================================================================
function Yg = vbm_vol_grad(Ym,vx_vol)
% ----------------------------------------------------------------------
% gradient map for edge description
% ----------------------------------------------------------------------
  [gx,gy,gz] = vbm_vol_gradient3(Ym,Ym>0); 
  Yg = abs(gx./vx_vol(1))+abs(gy./vx_vol(2))+abs(gz./vx_vol(3)); 
  %Yg = abs(gx)+abs(gy)+abs(gz); 
  %Yg = Yg ./ (Ym+eps);
end
%=======================================================================
function Ydiv = vbm_vol_div(Ym,vx_vol)
% ----------------------------------------------------------------------
% Divergence helps to identify all gyri that should not be in the GM, but 
% helps to improve the WM. Divergence estimation is very memory intensive 
% so it is better to limit the resolution.
% ----------------------------------------------------------------------
  [Ymr,resT2] = vbm_vol_resize(Ym,'reduceV',vx_vol,1.5,32);
  [gx,gy,gz]  = vbm_vol_gradient3(max(1/3,Ymr)); 
  Ydivr = smooth3(divergence(gy./vx_vol(1),gx./vx_vol(1),gz./vx_vol(3))); clear gx gy gz Ymr;
  Ydiv  = vbm_vol_resize(Ydivr,'dereduceV',resT2); 
end
%=======================================================================
function warn = vbm_io_addwarning(warn,id,mess)
  warn(end+1) = struct('identifier',id,'message',mess);
  warnstr = strrep(mess,'\\n','\n'); 
  warnstr = strrep(warnstr,'\n','\n         '); 
  vbm_io_cmd(sprintf(['\nWARNING: ' warnstr]),'warning');
end
%=======================================================================