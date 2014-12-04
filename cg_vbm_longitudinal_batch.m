function cg_vbm_longitudinal_batch(namefile)
% wrapper for using spm8 batch mode (see cg_vbm_batch.sh)
%
% namefile      - array of file names
%_______________________________________________________________________
% $Id: cg_vbm_longitudinal_batch.m 451 2013-03-26 13:38:49Z gaser $

if nargin < 1
	fprintf('Syntax: cg_vbm_longitudinal_batch(namefile)\n');
	exit
end

names = textread(namefile,'%s');
n = length(names);

if n == 0, error(sprintf('No file found in %s.\n',namefile)); end

spm_get_defaults;
cg_vbm_get_defaults;

global defaults vbm matlabbatch

for i=1:n
  matlabbatch{1}.spm.tools.vbm.tools.long.subj.mov{i} = names{i};
end

warning off
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);

spm_unlink(char(namefile))

exit
