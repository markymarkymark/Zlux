function [hdr,path,file] = dicom_header(path,wildcard)
% Syntax: hdr = dicom_header(path,wildcard)
% Read Dicom headers of files matching wildcard
%
% To read all files in a folder matching a wildcard, try:
%	hdr=dicom_header('C:\temp\','*.dcm');
%
% If you only want to read a single file:
%	hdr=dicom_header('C:\temp\image.dcm');
%
% If you want to be prompted for a filename, make path = ''
%	e.g. hdr=dicom_header('','*.dcm');
%
% NOTE: the hdr structs are returned as a cell array, 
%    since MATLAB can't array different size structures
%
% M.Elliott 2/07
%------------------------------------------------------------------------
file = '';

% --- Remember path of last time this routine was called ---
if (ispref(mfilename(),'DICOM_HEADER_defpath')), DICOM_HEADER_defpath = getpref(mfilename(),'DICOM_HEADER_defpath');
else, DICOM_HEADER_defpath = pwd();
end
% global DICOM_HEADER_defpath
% if (size(DICOM_HEADER_defpath,1) == 0) 
% 	DICOM_HEADER_defpath = 'C:\Documents and Settings\Tobey\My Documents\DATA\';
% end

% --- Handle args ---
if nargin < 2 , wildcard = '*.dcm'; end
if nargin < 1 , path     = ''	  ; end

% --- Prompt for user to choose a file, if none passed in ---
if isequal(path,'')
	[file, path] = uigetfile(wildcard,'Select a dicom file',DICOM_HEADER_defpath);
	if isequal(file,0)
        hdr = [];
		disp('Program cancelled.');
		return
    end
    setpref(mfilename(),'DICOM_HEADER_defpath',path);     % remember for next time
%	DICOM_HEADER_defpath = path;
	hdr = dicominfo([path file], 'UseDictionaryVR',true);

% --- Read passed in filename ---
elseif (nargin < 2)
%    if (numel(path) == 1)   % single file to read
    if (~ iscell(path))   % single file to read
        hdr = dicominfo(path, 'UseDictionaryVR',true); % This setting silences DicomDict warnings 
    else                    % cell array of filenames to read
        fullfiles = path;   % will read all files below
    end
end

% --- Done reading single dicom file? ---
if (exist('hdr'))
	return
end

% --- Returned will be a cell array ---
hdr    = {};

% --- Use passed in cell array of complete filenames ---
if (exist('fullfiles')) 
    nfiles = numel(fullfiles);
    for i=1:nfiles
        hdrx = dicominfo(fullfiles{i}, 'UseDictionaryVR',true);
        hdr{i} = hdrx;	
    end
 
% --- Get filenames matching search args ---
else    
    files  = dir([path wildcard]);
    if isequal(wildcard,'*')	% remove '.' and '..' files returned if wildcard = '*'
        nfiles = numel(files);
        files = files(3:nfiles);
    end
    
    % --- Read the file(s) ---
    nfiles = numel(files);
    for i=1:nfiles
        hdrx = dicominfo([path files(i).name], 'UseDictionaryVR',true);
        hdr{i} = hdrx;	
    end
end
return