function vbm_tst_qa_groups_test
% Test skript to create a batch structure to test vbm_tst_qa_groups.
%
%


%%
  test     = 6;
  method   = 1;

  opt.printgroup = 1;
  opt.qm         = {
%   'contrast'      'low (bad)  <--- contrast (GW contrast) ---> strong (better)'
%   'noise'         'low (good) <--- noise (noise (1/CNR) befor cor.) ---> strong (bad)'
%   'bias'          'low (good) <--- bias (inhomogeneity befor cor.) ---> strong (bad)'
    %'QMm' 'res_RMS'          'low (good) <--- NERR (NoiseEdgeResolutionRelation) ---> strong (bad)'
    %'res'           'low (good) <--- res (resolution) ---> strong (bad)'
 %   'noisec'        'low (good) <--- noisec (noise (1/CNR) after cor.) ---> strong (bad)'
 %   'biasc'         'low (good) <--- biasc (inhomogeneity after cor.) ---> strong (bad)'
 %  %'res'           'low (good) <--- res (resolution) ---> strong (bad)'
 %   'NERR'          'low (good) <--- NERR (NoiseEdgeResolutionRelation) ---> strong (bad)'
   % 'CNR'         'low (good) <--- CNR (noise after cor.) ---> strong (bad)'
   % 'CIR'         'low (good) <--- CIR (inhomogeneity after cor.) ---> strong (bad)'
   % 'res_vol'     'low (good) <--- res (resolution) ---> strong (bad)'
  };  
  varset=1;
  if varset==1
    opt.qm = {
      'QMm' 'NCR'     [  0.00    1/4] 
      'QMm' 'ICR'     [  0.00    1/4]
   %   'QMm' 'NERR'    [  0.05   0.40]
      'QMm' 'MPC'      [  0.10   0.30]
      };
  elseif varset==2
    opt.qm = {
      'QMo' 'NCR'     [  0.00    1/2] 
      'QMo' 'ICR'     [  0.00      1]
  %    'QMo' 'NERR'    [  0.05   0.80]
      'QMo' 'MPC'      [  0.05   0.40]
      };
  elseif varset==3
  end
  
  
  data=struct('name','','dirs',{},'groups',{}); di=0;
  % --------------------------------------------------------------------
  % ADNI Centervergleich
  % klare unterschiede bei nutzung von res
  % --------------------------------------------------------------------
  di=di+1;
  ADNIdirs = vbm_fileparts(vbm_findfiles('/Volumes/MyBook/MRData/qa_tst/ADNI/T1w','*1.5*',struct('dirs',1,'depth',1)),'f');
  ADNIdirs = strrep(strrep(ADNIdirs,'ANDI_1.5T','1.5T_ADNI'),'ANDI_3.0T','3.0T_ADNI');
  data(di).name   = 'ADNI1.5';
  data(di).dirs   = {'/Volumes/MyBook/MRData/qa_tst/XMLdir'};
  data(di).groups = [ADNIdirs' ADNIdirs'];
  % --------------------------------------------------------------------
  % ADNI Centervergleich
  % klare unterschiede bei nutzung von res
  % --------------------------------------------------------------------
  di=di+1;
  ADNIdirs = vbm_fileparts(vbm_findfiles('/Volumes/MyBook/MRData/qa_tst/ADNI/T1w','*',struct('dirs',1,'depth',1)),'f');
  ADNIdirs = strrep(strrep(ADNIdirs,'ANDI_1.5T','1.5T_ADNI'),'ANDI_3.0T','3.0T_ADNI');
  data(di).name   = 'ADNI full';
  data(di).dirs   = {'/Volumes/MyBook/MRData/qa_tst/XMLdir'};
  data(di).groups = [ADNIdirs' ADNIdirs'];
  % --------------------------------------------------------------------
  % Projekte / Teilprojekte
  % --------------------------------------------------------------------
  di=di+1;
  data(di).name   = 'Projects';
  data(di).dirs   = {'/Volumes/MyBook/MRData/qa_tst/XMLdir'};
  data(di).groups = {
    'IXI'       {'IXI'}
    'OASIS'     {'OASIS'}
    'NIH'       {'NIH'}
    'ADNI15'    {'1.5'}
    'ADNI30'    {'3.0'}
    'NISALS1'   {'EDM','GRZ','MILmano','TOR','WAR'}
    'NISALS2'   {'HAM','JEN','ROS','ULM'}
    'NISALS3'   {'BOC','MIA','OXF'}
    'NISALS4'   {'EDI'}
    };
  % --------------------------------------------------------------------
  % NISALS Centren to other Projects
  % --------------------------------------------------------------------
  di=di+1;
  NISALSc = {'BOC','EDI','EDM','GRZ','HAM','JEN','MIA','MIL','OXF','ROS','TOR','ULM','WAR'};
  data(di).name   = 'Projects';
  data(di).dirs   = {'/Volumes/MyBook/MRData/qa_tst/XMLdir'};
  data(di).groups = {
    'IXI'       {'IXI'}
    'ADNI'      {'ADNI'}
    };
  data(di).groups = [data(di).groups; NISALSc' NISALSc'];
  % --------------------------------------------------------------------
  % NISALS Centren to other Projects
  % --------------------------------------------------------------------
  di=di+1;
  NISALSc = {'BOC','EDI','EDM','GRZ','HAM','JEN','MIA','MIL','OXF','ROS','TOR','ULM','WAR'};
  data(di).name   = 'NISALS Center';
  data(di).dirs   = {'/Volumes/MyBook/MRData/qa_tst/XMLdir'};
  data(di).groups = [NISALSc' NISALSc'];
  %data(di).groups = [data(di).groups; NISALSc' NISALSc'];
  % --------------------------------------------------------------------
  % NISALS HC
  % --------------------------------------------------------------------
  di=di+1;
  NISALSc=unique(vbm_fileparts(vbm_findfiles('/Volumes/vbmDB/MRData/release20140211/pre/vbm8/NISALS/HC','*',struct('dirs',1,'depth',1)),'f'));
  NISALSc=setxor(NISALSc,{'C016'});
  data(di).name   = 'NISALS Center HC';
  data(di).dirs   = {'/Volumes/vbmDB/MRData/release20140211/pre/vbm8/NISALS/HC'};
  data(di).groups = [NISALSc' NISALSc'];   
  % --------------------------------------------------------------------
  % NISALS ALS
  % --------------------------------------------------------------------
  di=di+1;
  NISALSc=unique(vbm_fileparts(vbm_findfiles('/Volumes/vbmDB/MRData/release20140211/pre/vbm8/NISALS/ALS','*',struct('dirs',1,'depth',1)),'f'));
  NISALSc=setxor(NISALSc,{'C016'});
  data(di).name   = 'NISALS Center ALS';
  data(di).dirs   = {'/Volumes/vbmDB/MRData/release20140211/pre/vbm8/NISALS/ALS'};
  data(di).groups = [NISALSc' NISALSc'];   
  % --------------------------------------------------------------------
  % NISALS all
  % --------------------------------------------------------------------
  di=di+1;
  NISALSc=unique(vbm_fileparts(vbm_findfiles('/Volumes/vbmDB/MRData/release20140211/pre/vbm8/NISALS/','*',struct('dirs',1,'depth',2)),'f'));
  NISALSc=setxor(NISALSc,{'C016'});
  data(di).name   = 'NISALS Center';
  data(di).dirs   = {'/Volumes/vbmDB/MRData/release20140211/pre/vbm8/NISALS/'};
  %data(di).dirs   = {'/Volumes/4TBWD/tmp/NISALS/'};
  data(di).groups = [NISALSc' NISALSc'];   
  % --------------------------------------------------------------------
  % ALVIN
  % --------------------------------------------------------------------
  di=di+1;
  data(di).name   = 'ALVIN Protokoll';
  data(di).dirs   = {'/Volumes/MyBook/MRData/vbm_tst/vbm12i/SRS/ALVIN/'};
  data(di).groups = {
    'A1',{'_A1-'}
    'A2',{'_A2-'}
    'A3',{'_A3-'}
    'A4',{'_A4-'}
    'B1',{'_B1-'}
    'B2',{'_B2-'}
    'B3',{'_B3-'}
    'B4',{'_B4-'}
  };
  % --------------------------------------------------------------------
  % INDI
  % --------------------------------------------------------------------
  di=di+1;
  data(di).name   = 'INDI';
  data(di).dirs   = {'/Volumes/vbmDB/MRData/release20140211/pre/vbm8/INDI/'};
  subdirs = vbm_findfiles(data(di).dirs,'*',struct('dirs',1,'depth',2))';
  for fi=1:numel(subdirs), [pp,subdirs{fi}]=fileparts(subdirs{fi}); end
  data(di).groups = [
    subdirs subdirs
  ];

  %%
  for di = 7; %1:numel(data)
    files = cell(size(data(di).groups,1),1);
    data(di).groups(:,1) = strrep(data(di).groups(:,1),'_',''); 
    for gfi = 1:size(data(di).groups,1)
      files{gfi} = {}; 
      if iscell(data(di).groups{gfi,2})
        for gffi=1:numel(data(di).groups{gfi,2})
          for pi=1:numel(data(di).dirs)
            files{gfi} = [files{gfi}; vbm_findfiles(data(di).dirs{pi},['vbm_*' data(di).groups{gfi,2}{gffi} '*.xml'])'];
          end
        end
      else
        for pi=1:numel(data(di).dirs)
          files{gfi} = [files{gfi}; vbm_findfiles(data(di).dirs{pi},['vbm_*' data(di).groups{gfi,2} '*.xml'])'];
        end
      end
    end
    groups = data(di).groups(:,1);
    for gfi = size(data(di).groups,1):-1:1
      if numel(files{gfi})<4, files(gfi)=[]; groups(gfi)=[]; end
    end
    %
    vbm_tst_qa_groups(files,groups,opt.qm,opt.printgroup,data(di).name)
  end
  
end
function varargout=vbm_fileparts(files,part)
 
  files=cellstr(files); 
  
  if exist('part','var')
    varargout{1}=cell(size(files));
    switch part
      case {1,'p','path'}
        for fi=1:numel(files)
          varargout{1}{fi}=spm_fileparts2(files{fi});
        end
      case {2,'f','file'}
        for fi=1:numel(files)
          [pp,varargout{1}{fi}]=spm_fileparts2(files{fi});
        end
      case {3,'e'}
        for fi=1:numel(files)
          [pp,ff,varargout{1}{fi}]=spm_fileparts2(files{fi});
        end
      case {4,'i','image','dimension'}
        for fi=1:numel(files)
          [pp,ff,varargout{1}{fi}]=spm_fileparts2(files{fi});
        end
      otherwise
        error('MATLAB:vbm_fileparts:unkown part');
    end
  else
    if nargout>0, varargout{1}=cell(size(files)); end
    if nargout>1, varargout{2}=cell(size(files)); end
    if nargout>2, varargout{3}=cell(size(files)); end
    if nargout>3, varargout{4}=cell(size(files)); end
    if nargout>4, error('MATLAB:vbm_fileparts:to many outputs'); end

    switch nargout
      case 1, for fi=1:numel(files), varargout{1}{fi}=spm_fileparts2(files{fi}); end
      case 2, for fi=1:numel(files), [varargout{1}{fi},varargout{2}{fi}]=spm_fileparts2(files{fi}); end
      case 3, for fi=1:numel(files), [varargout{1}{fi},varargout{2}{fi},varargout{3}{fi}]=spm_fileparts2(files{fi}); end
      case 4, for fi=1:numel(files), [varargout{1}{fi},varargout{2}{fi},varargout{3}{fi},varargout{4}{fi}]=spm_fileparts2(files{fi}); end
    end
  end
  
  function [pp,ff,ee,dd]=spm_fileparts2(file)
    [pp,ff,ee,dd]=spm_fileparts(file);
    if isdir(file), ff=[ff ee]; ee=''; end
  end
end