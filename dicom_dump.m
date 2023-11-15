function [stat,h] = dicom_dump(filename,outfile,make_xml)
% Dump header contents of a dicom image file
% Include Siemens private dicom MR header if relevant (i.e. Siemens file)
% To make this into a standalone executable:
%   mcc -R -nodisplay -R -nojvm -m dicom_dump -a spm_dicom_dict.mat

stat = 0;
h = [];

% --- figure out if this is called as a subroutine ---
st = dbstack();
ismain = (size(st,1) == 1); % if no one called us, we're main-level routine

% --- if not 'mcc', let user choose a dicom file if not supplied --
if (~isdeployed)
    if (nargin < 1) || isempty(filename)
        if (ispref(mfilename(),'lastpath')),  lastpath = getpref(mfilename(),'lastpath');   else, lastpath = pwd();  end
        [file, path] = uigetfile({'*.dcm;*.MR;*.IMA';'*.*'},'Select a Dicom file',lastpath);
        if isequal(file,0), return; end
        setpref(mfilename(),'lastpath',path);
        filename = [path file];
    end

% --- standalone executable mode, check for supplied filename ---
else
    if (nargin < 1)
        fprintf(2,'usage: dicom_dump <dicomfile or directory> [outputfile] [make_xml=0/1]\n');
        exit(1);
    end
end

% --- open output file for writing ---
fp = 1; % default is write to stdout (i.e. terminal)
if (nargin > 1)
    if (~isempty(outfile))
        [fp,errmess] = fopen(outfile,'w');
        if (fp < 0)
            error(errmess);
            if (isdeployed && ismain), exit(1); end
            return; 
        end
    end
end

% --- XML or plain text? ---
if (nargin < 3)
    if (fp == 1), make_xml = 0;     % default is plain text if output is to stdout
    else          make_xml = 1;     % default is XML if output is a file
    end
else
    if (isdeployed && ismain), make_xml = str2num(make_xml); end % standalone exec will have string args
end

% --- Passed in a dicom header ---
if (isstruct(filename))
    filenames{1} = filename.Filename;
    nfiles = 1;
    
% --- All Dicoms in a folder ---
elseif (isdir(filename))
    path   = filename;
    files  = dir([path filesep '*.dcm']);
    if (isempty(files)), error('Found no dicom files in folder!'); end
    nfiles = numel(files);
    for i=1:nfiles, filenames{i} = [path filesep files(i).name]; end

% --- One explicit dicom file ---
else
    filenames{1} = filename;
    nfiles       = 1;
end

% --- Run through all files ---
for i=1:nfiles
    
    % --- Get Public dicom header ---
    h = dicominfo(filenames{i});
    
    % --- Append Siemens Private header info ---
    [h,status] = dicom_get_siemens(h);
    if (status == 0)                        % error
        if (isdeployed && ismain), exit(1); end
        return;
    end
    
    % --- init XML (if needed), and get series descrip ---
    if (i == 1)        
        % --- start XML ---
        if (make_xml), fprintf(fp,'<dcmSequence>\n'); end
        
        % --- Make inferences about the whole series ---
%        hseries = get_series_info(h);
%         status = print_structure(fp,hseries,'',make_xml);
%         if (status == 0)
%             if (isdeployed), exit(1); end
%             return;
%         end
    end
    
    % --- Now make nice text dump of next dicom header ---
    if (make_xml), fprintf(fp,'<dcmFile index=''%1d''>\n',i); end
    status = print_structure(fp,h,'',make_xml);
    if (status == 0);
        if (isdeployed && ismain), exit(1); end
        return;
    end
    if (make_xml), fprintf(fp,'</dcmFile>\n'); end
end

% --- close XML wrapper ---
if (make_xml), fprintf(fp,'</dcmSequence>\n'); end
if (fp ~= 1), fclose(fp); end
if (isdeployed && ismain), exit(0); end
stat = 1;
return


function hseries = get_series_info(h)
% Build a structure of general MRI series info

hseries.Modality  = 'MRI';
        
% --- Figure out image type ---
if (~isfield(h,'SequenceName') || isempty(h.SequenceName))
    hseries.ImageCategory = 'Unknown';
    hseries.ImageType     = 'Unknown';
    hseries.Contrast      = 'Unknown';
    
else
    % ---remove leading '*' (??)
    
    if (h.SequenceName(1) == '*'), h.SequenceName = h.SequenceName(2:length(h.SequenceName)); end
    
    % --- parse header for type of image ---
    if (strncmpi(h.SequenceName,'tse',3))
        hseries.ImageCategory = 'Structural';
        hseries.Imagetype     = 'TSE';
        hseries.Contrast      = 'T2';
    elseif (strncmpi(h.SequenceName,'tfl3d',5))
        hseries.ImageCategory = 'Structural';
        hseries.Imagetype     = 'MPRAGE';
        hseries.Contrast      = 'T1';
    elseif (strncmpi(h.SequenceName,'fl2d1',5))
        hseries.ImageCategory = 'Structural';
        hseries.Imagetype     = 'Localizer';
        hseries.Contrast      = 'T2*';
    elseif (strncmpi(h.SequenceName,'fl2d2',5))
        hseries.ImageCategory = 'B0Map';
        hseries.Imagetype     = 'GRE';
        hseries.Contrast      = 'T2*';
    elseif (strncmpi(h.SequenceName,'fm2d2',5))
        hseries.ImageCategory = 'B0Map';
        hseries.Imagetype     = 'GRE';
        hseries.Contrast      = 'T2*';
    elseif (strncmpi(h.SequenceName,'epfid2d',7))
        hseries.ImageCategory = 'BOLD';
        hseries.ImageType     = 'GRE-EPI';
        hseries.Contrast      = 'T2*';
    elseif (strncmpi(h.SequenceName,'epse2d',6))
        hseries.ImageCategory = 'PCASL';
        hseries.ImageType     = 'SE-EPI';
        hseries.Contrast      = 'T2';
    elseif (strncmpi(h.SequenceName,'ep_b',4))
        hseries.ImageCategory = 'DTI';
        hseries.ImageType     = 'SE-EPI';
        hseries.Contrast      = 'Diffusion';
    else
        hseries.ImageCategory = 'Unknown';
        hseries.ImageType     = 'Unknown';
        hseries.Contrast      = 'Unknown';
    end
end
return
