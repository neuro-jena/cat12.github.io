function out = cat_surf_vol2surf(varargin)
% Project volume data to a surface and create a texture file.
% ______________________________________________________________________
% P = cat_surf_vol2surf(job)
% 
% job.data_mesh_lh  .. lh mesh files
% job.data_vol      .. volume for mapping
% job.verb          .. verbose (default: 1)
% job.gifti         .. output gifti (default: 0)
% job.interp        .. interpolation type (default 'linear')
% job.mapping       .. mapping type 
%   .abs_mapping    .. absolute mapping distance
%     .start        .. start point of the vector in mm
%     .steps        .. number of grid steps
%     .end          .. end point of the vector in mm
%   .rel_mapping    .. relative mapping distance
%     .start        .. start point of the vector
%     .steps        .. number of grid steps
%     .end          .. end point of the vector
% job.datafieldname .. new fieldname
% 
% ______________________________________________________________________
% Robert Dahnke
% $Id$
 
  spm_clf('Interactive'); 
 
  if nargin == 1
    job = varargin{1};
  else 
    help cat_surf_vol2surf; return
  end
  
  n_vol  = numel(job.data_vol);
  n_surf = numel(job.data_mesh_lh);
  
  % if only 1 surface but multiple volumes are given then fill
  % up the missing surface names with the single surface name
  if (n_surf == 1) && (n_vol > 1)
    for i=2:n_vol
      job.data_mesh_lh{i} = job.data_mesh_lh{1};
    end
  end
  
  def.verb  = 1; 
  def.gifti = 0; 
  def.debug = 0; 
  def.interp{1} = 'linear'; 
  def.sample{1} = 'maxabs'; 
  def.datafieldname = 'intensity';
  def.fsavgDir  = fullfile(spm('dir'),'toolbox','cat12','templates_surfaces'); 
  job = cat_io_checkinopt(job,def);
  
  %%
  side  = {'data_mesh_lh','data_mesh_rh'};
  sside = {'sinfo_lh','sinfo_rh'};
  
  if ~isfield(job,'data_mesh_rh')
    job.data_mesh_rh = cat_surf_rename(job.data_mesh_lh,'side','rh');
  end
  
  job.sinfo_lh = cat_surf_info(job.data_mesh_lh);
  job.sinfo_rh = cat_surf_info(job.data_mesh_rh);
  template = job.sinfo_lh(1).template;
  
  %% Mapping command 
  % --------------------------------------------------------------------
  if isfield(job.mapping,'abs_mapping'), mapping = 'abs_mapping'; else mapping = 'rel_mapping'; end
  
  mapdef.class = 'GM';
  job.mapping.(mapping) = cat_io_checkinopt( job.mapping.(mapping),mapdef);
 
  mappingstr = sprintf('-%s -%s -steps "%d" -start "%0.4f" -end "%0.4f"',...
       job.interp{1},job.sample{1}, job.mapping.(mapping).steps, job.mapping.(mapping).startpoint,...
       job.mapping.(mapping).endpoint);   
  
  %% display something
  spm_clf('Interactive'); 
  spm_progress_bar('Init',numel(job.data_vol),'Mapped Volumes','Volumes Complete');
  P.data = cell(numel(job.data_vol),2);
  P.relmap = cell(numel(job.data_vol),2);
  P.thick = cell(numel(job.data_vol),2);
  
  if template
    for vi=1:numel(job.data_vol)
      [ppv,ffv,eev] = spm_fileparts(job.data_vol{vi});
      
      % replace '.img' extension by '.hdr' extension to work with CAT
      if strcmp(eev,'.img')
        eev = '.hdr';
      end
      
      P.vol{vi} = fullfile(ppv,[ffv eev]);

      % replace dots in volume name with "_"
      ffv(strfind(ffv,'.')) = '_';
      
      for si=1:numel(side)

        % also add volume name to differentiate between multiple volumes
        P.data(vi,si) = cat_surf_rename(job.(sside{si})(vi),...
          'preside','','pp',ppv,'dataname',[job.datafieldname '_' ffv],'name',job.(sside{si})(vi).name);

        P.thickness(vi,si) = cat_surf_rename(job.(sside{si})(vi).Pmesh,...
            'preside','','pp',job.fsavgDir,'dataname','thickness','ee','');

        switch mapping
          case 'abs_mapping'
            switch job.mapping.(mapping).surface
              case {1,'Central'},  addstr = ''; 
              case {2,'WM'},   addstr = sprintf(' -offset_value  0.5 -offset "%s" ',P.thickness{vi,si}); % + half thickness
              case {3,'Pial'}, addstr = sprintf(' -offset_value -0.5 -offset "%s" ',P.thickness{vi,si}); % - half thickness 
            end
          case 'rel_mapping'
            switch job.mapping.(mapping).class
              case {1,'GM'},  addstr = sprintf(' -thickness "%s" ',P.thickness{vi,si}); 
              case {2,'WM'},  error('Not yet supported');
              case {3,'CSF'}, error('Not yet supported'); 
            end
        end

        % map values
        cmd = sprintf('CAT_3dVol2Surf %s %s "%s" "%s" "%s"',...
          mappingstr, addstr,job.(sside{si})(vi).Pmesh, P.vol{vi}, P.data{vi,si});
        [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,job.debug);
        
        if job.verb
          fprintf('Display %s\n',spm_file(P.data{vi,si},'link','cat_surf_display(''%s'')'));
        end
      end
            
      spm_progress_bar('Set',vi);
    end
   
  else
    for vi=1:numel(job.data_vol)
      
      [ppv,ffv,eev] = spm_fileparts(job.data_vol{vi});
      
      % replace '.img' extension by '.hdr' extension to work with CAT
      if strcmp(eev,'.img')
        eev = '.hdr';
      end
      
      P.vol{vi} = fullfile(ppv,[ffv eev]);
       
      if ~strfind(ffv,job.(sside{1})(vi).name)
        cat_io_cprintf('warn',sprintf('Surface and volume matching error.\n'))
        continue
      end
      
      % replace dots in volume name with "_"
      ffv(strfind(ffv,'.')) = '_';

      
      %%
      for si=1:numel(side)
        % also add volume name to differentiate between multiple volumes
        P.data(vi,si) = cat_surf_rename(job.(sside{si})(vi).Pmesh,...
            'preside','','pp',spm_fileparts(job.(sside{si})(vi).fname),...
            'dataname',[job.datafieldname '_' ffv]);

        P.data(vi,si) = strrep(P.data(vi,si),'.gii',''); % remove .gii extension
                
        P.thickness(vi,si) = cat_surf_rename(job.(sside{si})(vi).Pmesh,...
            'preside','','pp',spm_fileparts(job.(sside{si})(vi).fname),...
            'dataname','thickness','ee','');
        P.depthWM(vi,si) = cat_surf_rename(job.(sside{si})(vi).Pmesh,...
            'preside','','pp',spm_fileparts(job.(sside{si})(vi).fname),...
            'dataname','depthWM','ee','');
        P.depthCSF(vi,si) = cat_surf_rename(job.(sside{si})(vi).Pmesh,...
            'preside','','pp',spm_fileparts(job.(sside{si})(vi).fname),...
            'dataname','depthCSF','ee','');
          
        switch mapping
          case 'abs_mapping'
            switch job.mapping.(mapping).surface
              case {1,'Central'},  addstr = ''; 
              case {2,'WM'},   addstr = sprintf(' -offset_value  0.5 -offset "%s" ',P.thickness{vi,si}); % + half thickness
              case {3,'Pial'}, addstr = sprintf(' -offset_value -0.5 -offset "%s" ',P.thickness{vi,si}); % - half thickness 
            end
          case 'rel_mapping'
            switch job.mapping.(mapping).class
              case {1,'GM'},  addstr = sprintf(' -thickness "%s" ',P.thickness{vi,si}); 
              case {2,'WM'},  error('Not yet supported');
              case {3,'CSF'}, error('Not yet supported'); 
            end
        end
        
        cmd = sprintf('CAT_3dVol2Surf %s %s "%s" "%s" "%s"',...
          mappingstr, addstr, job.(sside{si})(vi).Pmesh, P.vol{vi}, P.data{vi,si});
        [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,job.debug);
        
        if job.gifti==1
          P.data{vi,si} = char(cat_io_FreeSurfer('fs2gii',struct('data',job.(sside{si})(vi).Pmesh,'cdata',P.data{vi,si},'delete',0)));
        end
        
        if vi==1 && si==1 
          
          if job.debug 
            fprintf('\n%s\n',RS);
            fprintf('\nMappingstring: %s\n',mappingstr);
          end
        end
        
        if job.verb
          fprintf('Display %s\n',spm_file(P.data{vi,si},'link','cat_surf_display(''%s'')'));
        end
      
      end
    
      spm_progress_bar('Set',vi);
    end
  end
  
  % prepare output
  out.lh = P.data(:,1);
  out.rh = P.data(:,2);

  spm_progress_bar('Clear');

end
