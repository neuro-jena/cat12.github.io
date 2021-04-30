function factorial_design = cat_conf_factorial(expert)
% Configuration file for second-level models with full factorial design
%__________________________________________________________________________
% Copyright (C) 2005-2016 Wellcome Trust Centre for Neuroimaging

% modified version of
% spm_cfg_factorial_design.m 6952 2016-11-25 16:03:13Z guillaume
% ______________________________________________________________________
%
% Christian Gaser, Robert Dahnke
% Structural Brain Mapping Group (http://www.neuro.uni-jena.de)
% Departments of Neurology and Psychiatry
% Jena University Hospital
% ______________________________________________________________________
% $Id$

if nargin == 0
  expert = cat_get_defaults('extopts.expertgui');
end

%--------------------------------------------------------------------------
% dir Directory
%--------------------------------------------------------------------------
dir         = cfg_files;
dir.tag     = 'dir';
dir.name    = 'Directory';
dir.help    = {'Select a directory where the SPM.mat file containing the specified design matrix will be written.'};
dir.filter  = 'dir';
dir.ufilter = '.*';
dir.num     = [1 1];

%--------------------------------------------------------------------------
% scans Scans
%--------------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Scans';
scans.help    = {'Select the images.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans.filter  = {'image','mesh'};
scans.ufilter = '.*';
scans.num     = [1 Inf];
scans.preview = @(f) spm_check_registration(char(f));


%==========================================================================
% t1 One-sample t-test
%==========================================================================
t1      = cfg_branch;
t1.tag  = 't1';
t1.name = 'One-sample t-test';
t1.val  = {scans};
t1.help = {'One-sample t-test.'};

%--------------------------------------------------------------------------
% scans1 Group 1 scans
%--------------------------------------------------------------------------
scans1         = cfg_files;
scans1.tag     = 'scans1';
scans1.name    = 'Group 1 scans';
scans1.help    = {'Select the images from sample 1.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans1.filter  = {'image','mesh'};
scans1.ufilter = '.*';
scans1.num     = [1 Inf];
scans1.preview = @(f) spm_check_registration(char(f));

%--------------------------------------------------------------------------
% scans2 Group 2 scans
%--------------------------------------------------------------------------
scans2         = cfg_files;
scans2.tag     = 'scans2';
scans2.name    = 'Group 2 scans';
scans2.help    = {'Select the images from sample 2.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans2.filter  = {'image','mesh'};
scans2.ufilter = '.*';
scans2.num     = [1 Inf];
scans2.preview = @(f) spm_check_registration(char(f));

%--------------------------------------------------------------------------
% dept Independence
%--------------------------------------------------------------------------
dept         = cfg_menu;
dept.tag     = 'dept';
dept.name    = 'Independence';
dept.help    = {
                'By default, the measurements are assumed to be independent between levels. '
                ''
                'If you change this option to allow for dependencies, this will violate the assumption of sphericity. It would therefore be an example of non-sphericity. One such example would be where you had repeated measurements from the same subjects - it may then be the case that, over subjects, measure 1 is correlated to measure 2. '
                ''
                'Restricted Maximum Likelihood (REML): The ensuing covariance components will be estimated using ReML in spm_spm (assuming the same for all responsive voxels) and used to adjust the statistics and degrees of freedom during inference. By default spm_spm will use weighted least squares to produce Gauss-Markov or Maximum likelihood estimators using the non-sphericity structure specified at this stage. The components will be found in SPM.xVi and enter the estimation procedure exactly as the serial correlations in fMRI models.'
}';
dept.labels  = {'Yes', 'No'};
dept.values  = {0 1};
dept.val     = {0};
dept.hidden  = expert<1;

%--------------------------------------------------------------------------
% deptn Independence (default is 'No')
%--------------------------------------------------------------------------
deptn         = dept;
deptn.help{1} = 'By default, the measurements are assumed to be dependent between levels. ';
deptn.val     = {1};

%--------------------------------------------------------------------------
% variance Variance
%--------------------------------------------------------------------------
variance         = cfg_menu;
variance.tag     = 'variance';
variance.name    = 'Variance';
variance.help    = {
                    'By default, the measurements in each level are assumed to have unequal variance. '
                    ''
                    'This violates the assumption of ''sphericity'' and is therefore an example of ''non-sphericity''.'
                    ''
                    'This can occur, for example, in a 2nd-level analysis of variance, one contrast may be scaled differently from another.  Another example would be the comparison of qualitatively different dependent variables (e.g. normals vs. patients).  Different variances (heteroscedasticy) induce different error covariance components that are estimated using restricted maximum likelihood (see below).'
                    ''
                    'Restricted Maximum Likelihood (REML): The ensuing covariance components will be estimated using ReML in spm_spm (assuming the same for all responsive voxels) and used to adjust the statistics and degrees of freedom during inference. By default spm_spm will use weighted least squares to produce Gauss-Markov or Maximum likelihood estimators using the non-sphericity structure specified at this stage. The components will be found in SPM.xVi and enter the estimation procedure exactly as the serial correlations in fMRI models.'
}';
variance.labels = {'Equal', 'Unequal'};
variance.values = {0 1};
variance.val    = {1};

%--------------------------------------------------------------------------
% gmsca Grand mean scaling
%--------------------------------------------------------------------------
gmsca         = cfg_menu;
gmsca.tag     = 'gmsca';
gmsca.name    = 'Grand mean scaling';
gmsca.help    = {
                 'This option is for PET or VBM data (not second level fMRI).'
                 ''
                 'Selecting YES will specify ''grand mean scaling by factor'' which could be eg. ''grand mean scaling by subject'' if the factor is ''subject''. '
                 ''
                 'Since differences between subjects may be due to gain and sensitivity effects, AnCova by subject could be combined with "grand mean scaling by subject" to obtain a combination of between subject proportional scaling and within subject AnCova. '
}';
gmsca.labels = {'No', 'Yes'};
gmsca.values = {0 1};
gmsca.val    = {0};
gmsca.hidden = expert<1;

%--------------------------------------------------------------------------
% ancova ANCOVA
%--------------------------------------------------------------------------
ancova         = cfg_menu;
ancova.tag     = 'ancova';
ancova.name    = 'ANCOVA';
ancova.help    = {
                  'This option is for PET or VBM data (not second level fMRI).'
                  ''
                  'Selecting YES will specify ''ANCOVA-by-factor'' regressors. This includes eg. ''Ancova by subject'' or ''Ancova by effect''. These options allow eg. different subjects to have different relationships between local and global measurements. '
}';
ancova.labels = {'No', 'Yes'};
ancova.values = {0 1};
ancova.val    = {0};
ancova.hidden = expert<1;

%==========================================================================
% t2 Two-sample t-test
%==========================================================================
t2      = cfg_branch;
t2.tag  = 't2';
t2.name = 'Two-sample t-test';
t2.val  = {scans1 scans2 dept variance gmsca ancova};
t2.help = {'Two-sample t-test.'};

%--------------------------------------------------------------------------
% scans Scans [1,2]
%--------------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Scans [1,2]';
scans.help    = {'Select the pair of images.'};
scans.filter  = {'image','mesh'};
scans.ufilter = '.*';
scans.num     = [2 2];

%--------------------------------------------------------------------------
% pair Pair
%--------------------------------------------------------------------------
pair         = cfg_branch;
pair.tag     = 'pair';
pair.name    = 'Pair';
pair.val     = {scans };
pair.help    = {'Add a new pair of scans to your experimental design.'};

%--------------------------------------------------------------------------
% generic Pairs
%--------------------------------------------------------------------------
generic         = cfg_repeat;
generic.tag     = 'generic';
generic.name    = 'Pairs';
generic.help    = {''};
generic.values  = {pair};
generic.val     = {pair};
generic.num     = [1 Inf];

%==========================================================================
% pt Paired t-test
%==========================================================================
pt      = cfg_branch;
pt.tag  = 'pt';
pt.name = 'Paired t-test';
pt.val  = {generic gmsca ancova};
pt.help = {'Paired t-test.'};

%--------------------------------------------------------------------------
% scans Scans
%--------------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Scans';
scans.help    = {'Select the images.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans.filter  = {'image','mesh'};
scans.ufilter = '.*';
scans.num     = [1 Inf];
scans.preview = @(f) spm_check_registration(char(f));

%--------------------------------------------------------------------------
% c Vector
%--------------------------------------------------------------------------
c         = cfg_entry;
c.tag     = 'c';
c.name    = 'Vector';
c.help    = {'Vector of covariate values.'};
c.strtype = 'r';
c.num     = [Inf 1];

%--------------------------------------------------------------------------
% cname Name
%--------------------------------------------------------------------------
cname         = cfg_entry;
cname.tag     = 'cname';
cname.name    = 'Name';
cname.help    = {'Name of covariate.'};
cname.strtype = 's';
cname.num     = [1 Inf];

%--------------------------------------------------------------------------
% iCC Centering
%--------------------------------------------------------------------------
iCC         = cfg_menu;
iCC.tag     = 'iCC';
iCC.name    = 'Centering';
iCC.help    = {
               ['Centering refers to subtracting the mean (central) value from the covariate values, ' ...
               'which is equivalent to orthogonalising the covariate with respect to the constant column.']
               ''
               ['Subtracting a constant from a covariate changes the beta for the constant term, but not that for the covariate. ' ...
               'In the simplest case, centering a covariate in a simple regression leaves the slope unchanged, ' ...
               'but converts the intercept from being the modelled value when the covariate was zero, ' ...
               'to being the modelled value at the mean of the covariate, which is often more easily interpretable. ' ...
               'For example, the modelled value at the subjects'' mean age is usually more meaningful than the (extrapolated) value at an age of zero.']
               ''
               ['If a covariate value of zero is interpretable and/or you wish to preserve the values of the covariate then choose ''No centering''. ' ...
               'You should also choose not to center if you have already subtracted some suitable value from your covariate, ' ...
               'such as a commonly used reference level or the mean from another (e.g. larger) sample.']
               ''
               };
iCC.labels = {'Overall mean', 'No centering'};
iCC.values = {1 5};
iCC.val    = {1};

%--------------------------------------------------------------------------
% mcov Covariate
%--------------------------------------------------------------------------
mcov       = cfg_branch;
mcov.tag   = 'mcov';
mcov.name  = 'Covariate';
mcov.val   = {c cname iCC};
mcov.help  = {'Add a new covariate to your experimental design.'};

%--------------------------------------------------------------------------
% generic Covariates
%--------------------------------------------------------------------------
generic        = cfg_repeat;
generic.tag    = 'generic';
generic.name   = 'Covariates';
generic.help   = {'Covariates'};
generic.values = {mcov};
generic.num    = [0 Inf];

%--------------------------------------------------------------------------
% incint Intercept
%--------------------------------------------------------------------------
incint = cfg_menu;
incint.tag = 'incint';
incint.name = 'Intercept';
incint.help = {['By default, an intercept is always added to the model. ',...
    'If the covariates supplied by the user include a constant effect, ',...
    'the intercept may be omitted.']};
incint.labels = {'Include Intercept','Omit Intercept'};
incint.values = {1,0};
incint.val    = {1};

%==========================================================================
% mreg Multiple regression
%==========================================================================
mreg         = cfg_branch;
mreg.tag     = 'mreg';
mreg.name    = 'Multiple regression';
mreg.val     = {scans generic incint};
mreg.help    = {'Multiple regression.'};

%--------------------------------------------------------------------------
% name Name
%--------------------------------------------------------------------------
name         = cfg_entry;
name.tag     = 'name';
name.name    = 'Name';
name.help    = {'Name of factor, eg. ''Repetition''.'};
name.strtype = 's';
name.num     = [1 Inf];

%--------------------------------------------------------------------------
% levels Levels
%--------------------------------------------------------------------------
levels         = cfg_entry;
levels.tag     = 'levels';
levels.name    = 'Levels';
levels.help    = {'Enter number of levels for this factor, eg. 2.'};
levels.strtype = 'n';
levels.num     = [1 1];

%--------------------------------------------------------------------------
% fact Factor
%--------------------------------------------------------------------------
fact         = cfg_branch;
fact.tag     = 'fact';
fact.name    = 'Factor';
fact.val     = {name levels dept variance gmsca ancova };
fact.help    = {'Add a new factor to your experimental design.'};

%--------------------------------------------------------------------------
% generic Factors
%--------------------------------------------------------------------------
genericf        = cfg_repeat;
genericf.tag    = 'generic';
genericf.name   = 'Factors';
genericf.help   = {'Specify your design a factor at a time.'};
genericf.values = {fact};
genericf.val    = {fact};
genericf.num    = [1 Inf];

%--------------------------------------------------------------------------
% levels Levels
%--------------------------------------------------------------------------
levels         = cfg_entry;
levels.tag     = 'levels';
levels.name    = 'Levels';
levels.help    = {
                  'Enter a vector or scalar that specifies which cell in the factorial design these images belong to. The length of this vector should correspond to the number of factors in the design'
                  ''
                  'For example, length 2 vectors should be used for two-factor designs eg. the vector [2 3] specifies the cell corresponding to the 2nd-level of the first factor and the 3rd level of the 2nd factor.'
}';
levels.strtype = 'n';
levels.num     = [Inf 1];

%--------------------------------------------------------------------------
% scans Scans
%--------------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Scans';
scans.help    = {'Select the images for this cell.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans.filter  = {'image','mesh'};
scans.ufilter = '.*';
scans.num     = [1 Inf];

%--------------------------------------------------------------------------
% icell Cell
%--------------------------------------------------------------------------
icell         = cfg_branch;
icell.tag     = 'icell';
icell.name    = 'Cell';
icell.val     = {levels scans };
icell.help    = {'Enter data for a cell in your design.'};

%--------------------------------------------------------------------------
% scell Cell
%--------------------------------------------------------------------------
scell         = cfg_branch;
scell.tag     = 'icell';
scell.name    = 'Cell';
scell.val     = {scans };
scell.help    = {'Enter data for a cell in your design.'};

%--------------------------------------------------------------------------
% generic Specify cells
%--------------------------------------------------------------------------
generic1f         = cfg_repeat;
generic1f.tag     = 'generic';
generic1f.name    = 'Cells';
generic1f.help    = {'Enter the scans a cell at a time.'};
generic1f.values  = {icell};
generic1f.val     = {icell};
generic1f.num     = [1 Inf];

%--------------------------------------------------------------------------
% generic Specify cells
%--------------------------------------------------------------------------
generic2         = cfg_repeat;
generic2.tag     = 'generic';
generic2.name    = 'Cells';
generic2.help    = {'Enter the scans a cell at a time.'};
generic2.values  = {scell};
generic2.val     = {scell};
generic2.num     = [1 Inf];

%==========================================================================
% anova One-way ANOVA 
%==========================================================================
anova         = cfg_branch;
anova.tag     = 'anova';
anova.name    = 'One-way ANOVA';
anova.val     = {generic2 dept variance gmsca ancova};
anova.help    = {'One-way Analysis of Variance (ANOVA).'};

%--------------------------------------------------------------------------
% con Contrasts
%--------------------------------------------------------------------------
con        = cfg_menu;
con.tag    = 'contrasts';
con.name   = 'Generate contrasts';
con.help   = {'Automatically generate the contrasts necessary to test for all main effects and interactions.'};
con.labels = {'Yes', 'No'};
con.values = {1 0};
con.val    = {1};

%==========================================================================
% fd Full factorial
%==========================================================================
fd         = cfg_branch;
fd.tag     = 'fd';
fd.name    = 'Cross-sectional data (Full factorial)';
fd.val     = {genericf generic1f con};
fd.help    = {
              'This option is best used when you wish to test for all main effects and interactions in one-way, two-way or three-way ANOVAs. Design specification proceeds in 2 stages. Firstly, by creating new factors and specifying the number of levels and name for each. Nonsphericity, ANOVA-by-factor and scaling options can also be specified at this stage. Secondly, scans are assigned separately to each cell. This accomodates unbalanced designs.'
              ''
              'For example, if you wish to test for a main effect in the population from which your subjects are drawn and have modelled that effect at the first level using K basis functions (eg. K=3 informed basis functions) you can use a one-way ANOVA with K-levels. Create a single factor with K levels and then assign the data to each cell eg. canonical, temporal derivative and dispersion derivative cells, where each cell is assigned scans from multiple subjects.'
              ''
              'SPM will also automatically generate the contrasts necessary to test for all main effects and interactions.'
}';

%--------------------------------------------------------------------------
% name Name
%--------------------------------------------------------------------------
name         = cfg_entry;
name.tag     = 'name';
name.name    = 'Name';
name.help    = {'Name of factor, eg. ''Repetition''.'};
name.strtype = 's';
name.num     = [1 Inf];

%--------------------------------------------------------------------------
% fac Factor
%--------------------------------------------------------------------------
fac         = cfg_branch;
fac.tag     = 'fac';
fac.name    = 'Factor';
fac.val     = {name dept variance gmsca ancova };
fac.help    = {
               'Add a new factor to your design.'
               ''
               'If you are using the ''Subjects'' option to specify your scans and conditions, you may wish to make use of the following facility. There are two reserved words for the names of factors. These are ''subject'' and ''repl'' (standing for replication). If you use these factor names then SPM will automatically create replication and/or subject factors without you having to type in an extra entry in the condition vector.'
               ''
               'For example, if you wish to model Subject and Task effects (two factors), under Subjects->Subject->Conditions you should simply type in eg. [1 2 1 2] to specify just the ''Task'' factor level, instead of, eg. for the 4th subject the matrix [4 1;4 2;4 1;4 2].'
}';

%--------------------------------------------------------------------------
% generic Factors
%--------------------------------------------------------------------------
generic         = cfg_repeat;
generic.tag     = 'generic';
generic.name    = 'Factors';
generic.help    = {'Specify your design a factor at a time.'};
generic.values  = {fac};
generic.val     = {fac};
generic.num     = [1 Inf];

%--------------------------------------------------------------------------
% scans Scans
%--------------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Scans';
scans.help    = {'Select the images to be analysed.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans.filter  = {'image','mesh'};
scans.ufilter = '.*';
scans.num     = [1 Inf];

%--------------------------------------------------------------------------
% conds Conditions
%--------------------------------------------------------------------------
conds         = cfg_entry;
conds.tag     = 'conds';
conds.name    = 'Conditions';
conds.help    = {''};
conds.strtype = 'n';
conds.num     = [Inf Inf];

%--------------------------------------------------------------------------
% fsubject Subject
%--------------------------------------------------------------------------
fsubject      = cfg_branch;
fsubject.tag  = 'fsubject';
fsubject.name = 'Subject';
fsubject.val  = {scans conds};
fsubject.help = {'Enter data and conditions for a new subject.'};

%--------------------------------------------------------------------------
% generic Subjects
%--------------------------------------------------------------------------
generic1         = cfg_repeat;
generic1.tag     = 'generic';
generic1.name    = 'Subjects';
generic1.help    = {''};
generic1.values  = {fsubject};
generic1.val     = {fsubject};
generic1.num     = [1 Inf];

%--------------------------------------------------------------------------
% scans Scans
%--------------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Scans';
scans.help    = {'Select the images to be analysed.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans.filter  = {'image','mesh'};
scans.ufilter = '.*';
scans.num     = [1 Inf];

%--------------------------------------------------------------------------
% imatrix Factor matrix
%--------------------------------------------------------------------------
imatrix         = cfg_entry;
imatrix.tag     = 'imatrix';
imatrix.name    = 'Factor matrix';
imatrix.help    = {'Specify factor/level matrix as a nscan-by-4 matrix. Note that the first column of I is reserved for the internal replication factor and must not be used for experimental factors.'};
imatrix.strtype = 'n';
imatrix.num     = [Inf Inf];

%--------------------------------------------------------------------------
% specall Specify all
%--------------------------------------------------------------------------
specall         = cfg_branch;
specall.tag     = 'specall';
specall.name    = 'Specify all';
specall.val     = {scans imatrix };
specall.help    = {
                   'Specify (i) all scans in one go and (ii) all conditions using a factor matrix, I. This option is for ''power users''. The matrix I must have four columns and as as many rows as scans. It has the same format as SPM''s internal variable SPM.xX.I. '
                   ''
                   'The first column of I denotes the replication number and entries in the other columns denote the levels of each experimental factor.'
                   ''
                   'So, for eg. a two-factor design the first column denotes the replication number and columns two and three have entries like 2 3 denoting the 2nd level of the first factor and 3rd level of the second factor. The 4th column in I would contain all 1s.'
}';

%--------------------------------------------------------------------------
% fsuball Specify Subjects or all Scans & Factors
%--------------------------------------------------------------------------
fsuball         = cfg_choice;
fsuball.tag     = 'fsuball';
fsuball.name    = 'Specify Subjects or all Scans & Factors';
fsuball.val     = {generic1 };
fsuball.help    = {''};
fsuball.values  = {generic1 specall};

%--------------------------------------------------------------------------
% fnum Factor number
%--------------------------------------------------------------------------
fnum         = cfg_entry;
fnum.tag     = 'fnum';
fnum.name    = 'Factor number';
fnum.help    = {'Enter the number of the factor.'};
fnum.strtype = 'n';
fnum.num     = [1 1];

%--------------------------------------------------------------------------
% fmain Main effect
%--------------------------------------------------------------------------
fmain         = cfg_branch;
fmain.tag     = 'fmain';
fmain.name    = 'Main effect';
fmain.val     = {fnum };
fmain.help    = {'Add a main effect to your design matrix.'};

%--------------------------------------------------------------------------
% fnums Factor numbers
%--------------------------------------------------------------------------
fnums         = cfg_entry;
fnums.tag     = 'fnums';
fnums.name    = 'Factor numbers';
fnums.help    = {'Enter the numbers of the factors of this (two-way) interaction.'};
fnums.strtype = 'n';
fnums.num     = [2 1];

%--------------------------------------------------------------------------
% inter Interaction
%--------------------------------------------------------------------------
inter         = cfg_branch;
inter.tag     = 'inter';
inter.name    = 'Interaction';
inter.val     = {fnums };
inter.help    = {'Add an interaction to your design matrix.'};

%--------------------------------------------------------------------------
% maininters Main effects & Interactions
%--------------------------------------------------------------------------
maininters         = cfg_repeat;
maininters.tag     = 'maininters';
maininters.name    = 'Main effects & Interactions';
maininters.help    = {''};
maininters.values  = {fmain inter};
maininters.num     = [0 Inf]; % 0 for factor-covariate interaction(s) only

%==========================================================================
% anovaw One-way ANOVA within subject
%==========================================================================
anovaw      = cfg_branch;
anovaw.tag  = 'anovaw';
anovaw.name = 'One-way ANOVA - within subject';
anovaw.val  = {generic1 deptn variance gmsca ancova};
anovaw.help = {'One-way Analysis of Variance (ANOVA) - within subject.'};

%==========================================================================
% fblock Flexible factorial
%==========================================================================
fblock      = cfg_branch;
fblock.tag  = 'fblock';
fblock.name = 'Longitudinal data (Flexible factorial)';
fblock.val  = {generic fsuball maininters};
fblock.help = {
               'Create a design matrix a block at a time by specifying which main effects and interactions you wish to be included.'
               ''
               'This option is best used for one-way, two-way or three-way ANOVAs but where you do not wish to test for all possible main effects and interactions. This is perhaps most useful for PET where there is usually not enough data to test for all possible effects. Or for 3-way ANOVAs where you do not wish to test for all of the two-way interactions. A typical example here would be a group-by-drug-by-task analysis where, perhaps, only (i) group-by-drug or (ii) group-by-task interactions are of interest. In this case it is only necessary to have two-blocks in the design matrix - one for each interaction. The three-way interaction can then be tested for using a contrast that computes the difference between (i) and (ii).'
               ''
               'Design specification then proceeds in 3 stages. Firstly, factors are created and names specified for each. Nonsphericity, ANOVA-by-factor and scaling options can also be specified at this stage.'
               ''
               'Secondly, a list of scans is produced along with a factor matrix, I. This is an nscan x 4 matrix of factor level indicators (see xX.I below). The first factor must be ''replication'' but the other factors can be anything. Specification of I and the scan list can be achieved in one of two ways (a) the ''Specify All'' option allows I to be typed in at the user interface or (more likely) loaded in from the matlab workspace. All of the scans are then selected in one go. (b) the ''Subjects'' option allows you to enter scans a subject at a time. The corresponding experimental conditions (ie. levels of factors) are entered at the same time. SPM will then create the factor matrix I. This style of interface is similar to that available in SPM2.'
               ''
               'Thirdly, the design matrix is built up a block at a time. Each block can be a main effect or a (two-way) interaction. '
}';

%--------------------------------------------------------------------------
% c Vector
%--------------------------------------------------------------------------
c         = cfg_entry;
c.tag     = 'c';
c.name    = 'Vector';
c.help    = {
             'Vector of covariate values.'
             'Enter the covariate values ''''per subject'''' (i.e. all for subject 1, then all for subject 2, etc). Importantly, the ordering of the cells of a factorial design has to be the same for all subjects in order to be consistent with the ordering of the covariate values.'
}';
c.strtype = 'r';
c.num     = [Inf 1];

%--------------------------------------------------------------------------
% cname Name
%--------------------------------------------------------------------------
cname         = cfg_entry;
cname.tag     = 'cname';
cname.name    = 'Name';
cname.help    = {'Name of covariate.'};
cname.strtype = 's';
cname.num     = [1 Inf];

%--------------------------------------------------------------------------
% iCFI Interactions
%--------------------------------------------------------------------------
iCFI         = cfg_menu;
iCFI.tag     = 'iCFI';
iCFI.name    = 'Interactions';
iCFI.help    = {
                'For each covariate you have defined, there is an opportunity to create an additional regressor that is the interaction between the covariate and a chosen experimental factor. '
}';
iCFI.labels = {
               'None'
               'With Factor 1'
               'With Factor 2'
               'With Factor 3'
}';
iCFI.values = {1 2 3 4};
iCFI.val    = {1};

%--------------------------------------------------------------------------
% iCC Centering
%--------------------------------------------------------------------------
iCC         = cfg_menu;
iCC.tag     = 'iCC';
iCC.name    = 'Centering';
iCC.help    = {
               ['Centering, in the simplest case, refers to subtracting the mean (central) value from the covariate values, ' ...
               'which is equivalent to orthogonalising the covariate with respect to the constant column.']
               ''
               ['Subtracting a constant from a covariate changes the beta for the constant term, but not that for the covariate. ' ...
               'In the simplest case, centering a covariate in a simple regression leaves the slope unchanged, ' ...
               'but converts the intercept from being the modelled value when the covariate was zero, ' ...
               'to being the modelled value at the mean of the covariate, which is often more easily interpretable. ' ...
               'For example, the modelled value at the subjects'' mean age is usually more meaningful than the (extrapolated) value at an age of zero.']
               ''
               ['If a covariate value of zero is interpretable and/or you wish to preserve the values of the covariate then choose ''No centering''. ' ...
               'You should also choose not to center if you have already subtracted some suitable value from your covariate, ' ...
               'such as a commonly used reference level or the mean from another (e.g. larger) sample. ' ...
               'Note that ''User specified value'' has no effect, but is present for compatibility with earlier SPM versions.']
               ''
               ['Other centering options should only be used in special cases. ' ...
               'More complicated centering options can orthogonalise a covariate or a covariate-factor interaction with respect to a factor, ' ...
               'in which case covariate values within a particular level of a factor have their mean over that level subtracted. ' ...
               'As in the simple case, such orthogonalisation changes the betas for the factor used to orthogonalise, ' ...
               'not those for the covariate/interaction being orthogonalised. ' ...
               'This therefore allows an added covariate/interaction to explain some otherwise unexplained variance, ' ...
               'but without altering the group difference from that without the covariate/interaction. ' ...
               'This is usually *inappropriate* except in special cases. One such case is with two groups and covariate that only has meaningful values for one group ' ...
               '(such as a disease severity score that has no meaning for a control group); ' ...
               'centering the covariate by the group factor centers the values for the meaningful group and (appropriately) zeroes the values for the other group.']
               ''
}';
iCC.labels = {
              'Overall mean'
              'Factor 1 mean'
              'Factor 2 mean'
              'Factor 3 mean'
              'No centering'
              'User specified value'
              'As implied by ANCOVA'
              'GM'
}';
iCC.values = {1 2 3 4 5 6 7 8};
iCC.val    = {1};

%--------------------------------------------------------------------------
% cov Covariate
%--------------------------------------------------------------------------
cov         = cfg_branch;
cov.tag     = 'cov';
cov.name    = 'Covariate';
cov.val     = {c cname iCFI iCC};
cov.help    = {'Add a new covariate to your experimental design.'};

%--------------------------------------------------------------------------
% generic Covariates
%--------------------------------------------------------------------------
generic        = cfg_repeat;
generic.tag    = 'generic';
generic.name   = 'Covariates';
generic.help   = {'This option allows for the specification of covariates and nuisance variables (note that SPM does not make any distinction between effects of interest (including covariates) and nuisance effects).'};
generic.values = {cov};
generic.num    = [0 Inf];

%--------------------------------------------------------------------------
% multi_reg Multiple covariates
%--------------------------------------------------------------------------
cov         = cfg_files;
cov.tag     = 'files';
cov.name    = 'File(s)';
cov.val     = {{''}};
cov.help    = {
               'Select the *.mat/*.txt file(s) containing details of your multiple covariates. '
               ''
               'You will first need to create a *.mat file containing a matrix R or a *.txt file containing the covariates. Each column of R will contain a different covariate. Unless the covariates names are given in a cell array called ''names'' in the MAT-file containing variable R, the covariates will be named R1, R2, R3, ..etc.'
              }';
cov.filter  = 'mat';
cov.ufilter = '.*';
cov.num     = [0 Inf];

%--------------------------------------------------------------------------
% multi_cov Covariate
%--------------------------------------------------------------------------
multi_cov         = cfg_branch;
multi_cov.tag     = 'multi_cov';
multi_cov.name    = 'Covariates';
multi_cov.val     = {cov iCFI iCC};
multi_cov.help    = {'Add a new set of covariates to your experimental design.'};

%--------------------------------------------------------------------------
% generic2 Multiple covariates
%--------------------------------------------------------------------------
generic2        = cfg_repeat;
generic2.tag    = 'generic';
generic2.name   = 'Multiple covariates';
generic2.help   = {'This option allows for the specification of multiple covariates from TXT/MAT files.'};
generic2.values = {multi_cov};
generic2.num    = [0 Inf];
generic2.hidden  = expert<1;

%--------------------------------------------------------------------------
% tm_none None
%--------------------------------------------------------------------------
tm_none         = cfg_const;
tm_none.tag     = 'tm_none';
tm_none.name    = 'None';
tm_none.val     = {1};
tm_none.help    = {'No threshold masking'};

%--------------------------------------------------------------------------
% athresh Threshold
%--------------------------------------------------------------------------
athresh         = cfg_entry;
athresh.tag     = 'athresh';
athresh.name    = 'Threshold';
athresh.help    = {'Enter the absolute value of the threshold.'};
athresh.strtype = 'r';
athresh.num     = [1 1];
athresh.val     = {100};

%--------------------------------------------------------------------------
% tma Absolute
%--------------------------------------------------------------------------
tma         = cfg_branch;
tma.tag     = 'tma';
tma.name    = 'Absolute';
tma.val     = {athresh };
tma.help    = {
               'Images are thresholded at a given value and only voxels at which all images exceed the threshold are included. '
               ''
               'This option allows you to specify the absolute value of the threshold.'
}';

%--------------------------------------------------------------------------
% rthresh Threshold
%--------------------------------------------------------------------------
rthresh         = cfg_entry;
rthresh.tag     = 'rthresh';
rthresh.name    = 'Threshold';
rthresh.help    = {'Enter the threshold as a proportion of the global value.'};
rthresh.strtype = 'r';
rthresh.num     = [1 1];
rthresh.val     = {.8};

%--------------------------------------------------------------------------
% tmr Relative
%--------------------------------------------------------------------------
tmr         = cfg_branch;
tmr.tag     = 'tmr';
tmr.name    = 'Relative';
tmr.val     = {rthresh};
tmr.help    = {
               'Images are thresholded at a given value and only voxels at which all images exceed the threshold are included.'
               ''
               'This option allows you to specify the value of the threshold as a proportion of the global value.'
}';

%--------------------------------------------------------------------------
% tm Threshold masking
%--------------------------------------------------------------------------
tm         = cfg_choice;
tm.tag     = 'tm';
tm.name    = 'Threshold masking';
tm.val     = {tm_none};
tm.help    = {'Images are thresholded at a given value and only voxels at which all images exceed the threshold are included.'};
tm.values  = {tm_none tma tmr};

%--------------------------------------------------------------------------
% im Implicit Mask
%--------------------------------------------------------------------------
im        = cfg_menu;
im.tag    = 'im';
im.name   = 'Implicit Mask';
im.help   = {
             'An "implicit mask" is a mask implied by a particular voxel value. Voxels with this mask value are excluded from the analysis.'
             ''
             'For image data-types with a representation of NaN (see spm_type.m), NaN''s is the implicit mask value, (and NaN''s are always masked out).'
             ''
             'For image data-types without a representation of NaN, zero is the mask value, and the user can choose whether zero voxels should be masked out or not.'
             ''
             'By default, an implicit mask is used.'
}';
im.labels = {'Yes', 'No'};
im.values = {1 0};
im.val    = {1};

%--------------------------------------------------------------------------
% em Explicit Mask
%--------------------------------------------------------------------------
em         = cfg_files;
em.tag     = 'em';
em.name    = 'Explicit Mask';
em.val     = {{''}};
em.help    = {
              'Explicit masks are other images containing (implicit) masks that are to be applied to the current analysis.'
              ''
              'All voxels with value NaN (for image data-types with a representation of NaN), or zero (for other data types) are excluded from the analysis.'
              ''
              'Explicit mask images can have any orientation and voxel/image size. Nearest neighbour interpolation of a mask image is used if the voxel centers of the input images do not coincide with that of the mask image.'
}';
em.filter  = {'image','mesh'};
em.ufilter = '.*';
em.num     = [0 1];

%--------------------------------------------------------------------------
% masking Masking
%--------------------------------------------------------------------------
masking         = cfg_branch;
masking.tag     = 'masking';
masking.name    = 'Masking';
masking.val     = {tm im em};
masking.help    = {
                   'The mask specifies the voxels within the image volume which are to be assessed. SPM supports three methods of masking (1) Threshold, (2) Implicit and (3) Explicit. The volume analysed is the intersection of all masks.'
}';

%--------------------------------------------------------------------------
% g_yes Omit
%--------------------------------------------------------------------------
g_omit         = cfg_const;
g_omit.tag     = 'g_omit';
g_omit.name    = 'No';
g_omit.val     = {1};
g_omit.help    = {'Omit global scaling'};

%--------------------------------------------------------------------------
% global_uval Global values
%--------------------------------------------------------------------------
global_uval         = cfg_entry;
global_uval.tag     = 'global_uval';
global_uval.name    = 'Global values';
global_uval.help    = {'Enter the vector of global values.'};
global_uval.strtype = 'r';
global_uval.num     = [Inf 1];

%--------------------------------------------------------------------------
% g_user User
%--------------------------------------------------------------------------
g_user         = cfg_branch;
g_user.tag     = 'g_user';
g_user.name    = 'Global scaling';
g_user.val     = {global_uval};
g_user.help    = {'User defined  global effects (enter your own vector of global values).'};

%--------------------------------------------------------------------------
% g_ancova Ancova
%--------------------------------------------------------------------------
g_ancova         = cfg_branch;
g_ancova.tag     = 'g_ancova';
g_ancova.name    = 'ANCOVA';
g_ancova.val     = {global_uval};
g_ancova.help    = {'ANCOVA'};

%--------------------------------------------------------------------------
% globals TIV correction
%--------------------------------------------------------------------------
globals         = cfg_choice;
globals.tag     = 'globals';
globals.name    = 'Correction of TIV';
globals.val     = {g_ancova};
globals.values  = {g_omit g_ancova g_user};
globals.help    = {
                   'This option is to correct for TIV for VBM data by using TIV as covariate (Ancova) or by global scaling with TIV.'
                   ''
}';

%--------------------------------------------------------------------------
% gmsca_no No
%--------------------------------------------------------------------------
gmsca_no      = cfg_const;
gmsca_no.tag  = 'gmsca_no';
gmsca_no.name = 'No';
gmsca_no.val  = {1};
gmsca_no.help = {'No overall grand mean scaling.'};

%--------------------------------------------------------------------------
% gmscv Grand mean scaled value
%--------------------------------------------------------------------------
gmscv         = cfg_entry;
gmscv.tag     = 'gmscv';
gmscv.name    = 'Grand mean scaled value';
gmscv.help    = {'The default value of 50, scales the global flow to a physiologically realistic value of 50ml/dl/min.'};
gmscv.strtype = 'r';
gmscv.num     = [Inf 1];
gmscv.val     = {50};

%--------------------------------------------------------------------------
% gmsca_yes Yes
%--------------------------------------------------------------------------
gmsca_yes      = cfg_branch;
gmsca_yes.tag  = 'gmsca_yes';
gmsca_yes.name = 'Yes';
gmsca_yes.val  = {gmscv};
gmsca_yes.help = {'Scaling of the overall grand mean simply scales all the data by a common factor such that the mean of all the global values is the value specified. For qualitative data, this puts the data into an intuitively accessible scale without altering the statistics.'};

%--------------------------------------------------------------------------
% gmsca Overall grand mean scaling
%--------------------------------------------------------------------------
gmsca         = cfg_choice;
gmsca.tag     = 'gmsca';
gmsca.name    = 'Overall grand mean scaling';
gmsca.val     = {gmsca_no};
gmsca.help    = {
                 'Scaling of the overall grand mean simply scales all the data by a common factor such that the mean of all the global values is the value specified. For qualitative data, this puts the data into an intuitively accessible scale without altering the statistics. '
                 ''
                 'When proportional scaling global normalisation is used each image is separately scaled such that it''s global value is that specified (in which case the grand mean is also implicitly scaled to that value). So, to proportionally scale each image so that its global value is eg. 20, select <Yes> then type in 20 for the grand mean scaled value.'
                 ''
                 'When using AnCova or no global normalisation, with data from different subjects or sessions, an intermediate situation may be appropriate, and you may be given the option to scale group, session or subject grand means separately. '
}';
gmsca.values  = {gmsca_no gmsca_yes};

%--------------------------------------------------------------------------
% glonorm Normalisation
%--------------------------------------------------------------------------
glonorm         = cfg_menu;
glonorm.tag     = 'glonorm';
glonorm.name    = 'Normalisation';
glonorm.help    = {
                   'This option is for VBM data to correct for TIV as alternative to the use as covariate.'
                   ''
                   'Global nuisance effects such as total tissue volumes for VBM can be accounted for either by dividing the intensities in each image by the image''s global value (proportional scaling), or by including the global covariate as a nuisance effect in the general linear model (AnCova).'
                   ''
                   'Much has been written on which to use, and when. Basically, since proportional scaling also scales the variance term, it is appropriate for situations where the global measurement predominantly reflects gain or sensitivity. Where variance is constant across the range of global values, linear modelling in an AnCova approach has more flexibility, since the model is not restricted to a simple proportional regression. '
                   ''
                   '''Ancova by subject'' or ''Ancova by effect'' options are implemented using the ANCOVA options provided where each experimental factor (eg. subject or effect), is defined. These allow eg. different subjects to have different relationships between local and global measurements. '
                   ''
                   'Since differences between subjects may be due to gain and sensitivity effects, AnCova by subject could be combined with "grand mean scaling by subject" (an option also provided where each experimental factor is originally defined) to obtain a combination of between subject proportional scaling and within subject AnCova. '
}';
glonorm.labels = {'None', 'Proportional', 'ANCOVA'};
glonorm.values = {1 2 3};
glonorm.val    = {1};

%--------------------------------------------------------------------------
% globalm Global normalisation
%--------------------------------------------------------------------------
globalm      = cfg_branch;
globalm.tag  = 'globalm';
globalm.name = 'Global normalisation';
globalm.val  = {gmsca glonorm};
globalm.help = {
                'These options are for PET or VBM data (not second level fMRI).'
                ''
                '''Overall grand mean scaling'' simply scales all the data by a common factor such that the mean of all the global values is the value specified.'
                ''
                '''Normalisation'' refers to either proportionally scaling each image or adding a covariate to adjust for the global values.'
}';
globalm.hidden = expert<1;

%--------------------------------------------------------------------------
% voxel_cov Voxel-wise covariates
%--------------------------------------------------------------------------
cov         = cfg_files;
cov.tag     = 'files';
cov.name    = 'Scans';
cov.val     = {{''}};
cov.help    = {
             'Select the files with voxel-wise covariates (i.e. GM data).'
             ''
             'Importantly, the ordering of of the covariate files has to be consistent with the ordering of the cells in a factorial design.'
}';
cov.filter  = {'image','mesh'};
cov.ufilter = '.*';
cov.num     = [0 Inf];
cov.preview = @(f) spm_check_registration(char(f));

%--------------------------------------------------------------------------
% multi_cov Covariate
%--------------------------------------------------------------------------
iCC2          = iCC;
iCC2.hidden   = expert<1;

%--------------------------------------------------------------------------
% g_user User
%--------------------------------------------------------------------------
g_yes         = cfg_branch;
g_yes.tag     = 'g_user';
g_yes.name    = 'Yes';
g_yes.val     = {global_uval};
g_yes.help    = {'User defined  global effects (enter your own vector of global values).'};

%--------------------------------------------------------------------------
% globals2 Global calculation
%--------------------------------------------------------------------------
globals2         = cfg_choice;
globals2.tag     = 'globals';
globals2.name    = 'Global scaling';
globals2.val     = {g_omit};
globals2.values  = {g_omit g_yes};
globals2.help    = {
                   'This option is to correct/normalize structural (VBM) data by TIV using global scaling.'
                   ''
}';

voxel_cov         = cfg_branch;
voxel_cov.tag     = 'voxel_cov';
voxel_cov.name    = 'Voxel-wise covariate (experimental!)';
voxel_cov.val     = {cov iCFI iCC2 globals2};
voxel_cov.help    = {
    'This experimental option allows the specification of a voxel-wise covariate. This can be used (depending on the contrast defined) to (1) remove the confounding effect of structural data (e.g. GM) on functional data or (2) investigate the relationship (regression) between functional and structural data.'
    ''
    'In addition, an interaction can be modeled to examine whether the regression between functional and structural data differs between two groups.'
    ''
    'Please note that the saved vSPM.mat file can only be analyzed with the TFCE toolbox.'
    };

%--------------------------------------------------------------------------
% des Design
%--------------------------------------------------------------------------
% add voxel-wise covariates to full factorial design
fd.val     = {genericf generic1f con voxel_cov};

des         = cfg_choice;
des.tag     = 'des';
des.name    = 'Design';
des.val     = {fd };
des.help    = {''};
des.values  = {fd fblock };

%==========================================================================
% factorial_design Factorial design specification
%==========================================================================
factorial_design      = cfg_exbranch;
factorial_design.tag  = 'factorial_design';
factorial_design.name = 'Factorial design specification';
factorial_design.val  = {dir des generic generic2 masking globals};
factorial_design.help = {
    'Configuration of the design matrix, describing the general linear model, data specification, and other parameters necessary for the statistical analysis.'
    'These parameters are saved in a configuration file (SPM.mat), which can then be passed on to spm_spm.m which estimates the design. This is achieved by pressing the ''Estimate'' button. Inference on these estimated parameters is then handled by the SPM results section. '
    ''
    'This interface is used for setting up analyses of PET data, morphometric data, or ''second level'' (''random effects'') fMRI data, where first level models can be used to produce appropriate summary data that are then used as raw data for the second-level analysis. For example, a simple t-test on contrast images from the first-level turns out to be a random-effects analysis with random subject effects, inferring for the population based on a particular sample of subjects.'
    ''
    'A separate interface handles design configuration for first level fMRI time series.'
    ''
    'Various data and parameters need to be supplied to specify the design (1) the image files, (2) indicators of the corresponding condition/subject/group (2) any covariates, nuisance variables, or design matrix partitions (3) the type of global normalisation (if any) (4) grand mean scaling options (5) thresholds and masks defining the image volume to analyse. The interface supports a comprehensive range of options for all these parameters.'
    }';
factorial_design.prog = @cat_run_factorial_design;
factorial_design.vout = @vout_stats;


%==========================================================================
% function dep = vout_stats(job)
%==========================================================================
function dep = vout_stats(job)
dep(1)            = cfg_dep;
dep(1).sname      = 'SPM.mat File';
dep(1).src_output = substruct('.','spmmat');
dep(1).tgt_spec   = cfg_findspec({{'filter','mat','strtype','e'}});

%==========================================================================
% function out = cat_run_factorial_design(job)
%==========================================================================
function out = cat_run_factorial_design(job)
% SPM job execution function - factorial design specification
% Input:
% job    - harvested job data structure (see matlabbatch help)
% Output:
% out    - struct variable containing the name of the saved SPM.mat
%_________________________________________________________________________

% copy values from "global scaling" to "global calculation"
job.globalc = job.globals;

% check for voxel-wise covariate
voxel_covariate = false;
if isfield(job.des,'fd')
  if ~isempty(char(job.des.fd.voxel_cov.files))
    voxel_covariate = true;
    
    % number of covriate scans
    m = numel(job.des.fd.voxel_cov.files);
    
    % get number of scans
    n = 0;
    for i=1:numel(job.des.fd.icell)
      n = n + numel(job.des.fd.icell(i).scans);
    end
    
    if m~=n
      error('Number of covariate files (m=%d) differs from number of files (n=%d)',m,n);
    end
    
    % get global means for covariate
    gm = zeros(numel(job.des.fd.voxel_cov.files),1);
    for i=1:n
      dat = spm_data_read(spm_data_hdr_read(job.des.fd.voxel_cov.files{i}));
      gm(i) = mean(dat(isfinite(dat) & dat ~= 0));
    end    
    
    % add dummy covariate with global mean values to define design
    nc = numel(job.cov);
    job.cov(nc+1).c = gm - mean(gm);
    job.cov(nc+1).cname = 'voxel-wise covariate';
    job.cov(nc+1).iCFI = job.des.fd.voxel_cov.iCFI;  
    job.cov(nc+1).iCC = job.des.fd.voxel_cov.iCC;
  end
end

% if global scaling is selected set resp. fields for global normalisation
if strcmp(char(fieldnames(job.globalc)),'g_user')
  job.globalm.glonorm = 2;
  job.globalm.gmsca.gmsca_yes.gmscv = mean(job.globalc.g_user.global_uval);
elseif strcmp(char(fieldnames(job.globalc)),'g_ancova')
  job.globalc.g_user = job.globalc.g_ancova;
  % g_ancova field should be removed
  job.globalc = rmfield(job.globalc,'g_ancova');
  job.globalm.gmsca.gmsca_yes.gmscv = mean(job.globalc.g_user.global_uval);
  job.globalm.glonorm = 3;
else
  job.globalm.glonorm = 1;
  job.globalm.gmsca.gmsca_no = 1;
end

% call SPM factorial design
out = spm_run_factorial_design(job);
if voxel_covariate
  cat_stat_spm(out.spmmat{1});
  
  load(out.spmmat{1});
  SPM.xC(nc+1).P = cellstr(job.des.fd.voxel_cov.files);
  SPM.xC(nc+1).VC = spm_data_hdr_read(char(job.des.fd.voxel_cov.files));

  % save user defined global scalings
  try
    gSF = job.des.fd.voxel_cov.globals.g_user.global_uval;
    SPM.xC(nc+1).gSF = gSF;
  end
  
  % contrast should be defined right after model creation
  [Ic0,xCon] = spm_conman(SPM,'T',Inf,...
        '  Select contrast(s)...',' ',1);
      
  % set threshold values to skip interactive selection because we don't need that
  xSPM = SPM;
  xSPM.xCon      = xCon;
  xSPM.Ic        = Ic0;
  xSPM.Im        = '';
  xSPM.thresDesc = 'none';
  xSPM.u         = 0.001;
  xSPM.k         = 0;
  
  [SPM,xSPM] = spm_getSPM(xSPM);

  % save new voxel-wise vSPM.mat and remove SPM.mat because it should not
  % be used anymore
  save(fullfile(SPM.swd,'vSPM.mat'),'SPM','-v7.3');
  delete(fullfile(SPM.swd,'SPM.mat'))
  
  % update output field with new name
  out.spmmat{1} = fullfile(SPM.swd,'vSPM.mat');
  
  % delete beta_ and spm?_ files for voxel-wise covariate because these
  % files were estimated using spm_spm and are not valid
  for i=1:numel(SPM.xC(nc+1).cols)
    delete(fullfile(SPM.swd,sprintf('beta_%04d.*',SPM.xC(nc+1).cols(i))));
  end
  delete(fullfile(SPM.swd,sprintf('spm*_%04d.*',Ic0)));
  
  % print warning
  spm('alert!',sprintf('SPM12 cannot handle such designs with voxel-wise covariate.\nYou must now call the TFCE toolbox for statistical analysis.'));
else
  % remove old vSPM.mat if exist
  swd = fileparts(out.spmmat{1});
  delete(fullfile(swd,'vSPM.mat'));
end
