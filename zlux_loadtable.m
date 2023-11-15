% -------------------------------------------------------------------------
function [stat,tabd,matched,details] = zlux_loadtable(file,is_master,table_handle,master_tabd)

global hmatch reddot greendot

if (nargin < 3), table_handle = []; end

stat    = 0;
tabd    = [];
matched = -1;
details = '';

% --- if dicom, convert to XML ---
if (~exist(file,'file')), fprintf(2,'ERROR: %s does not exist\n',file); return; end
if (isdicom(file))
    dcm = dicom_header(file);
%     path = tempdir();       % make xml file in temporary folder
%     if (isempty(path))
%         [path,name] = fileparts(dcm.Filename);
%         if (isempty(path)), path = '.'; end
%         xmlfile = [path filesep() name '.xml'];
%     else
%         xmlfile = [path filesep() 'zlux_temp.xml'];
%     end
    xmlfile = [tempname() '.xml'];
    dicom_dump(dcm.Filename,xmlfile,1);
else
    xmlfile = file;
end

% --- read in XML ---
[h,htol] = zlux_readxml(xmlfile,1);
if (isdicom(file)), delete(xmlfile); end % delete temp XML file we made
if (isempty(h)); return; end

% --- Initialize table data with master dicom header info ---
if (is_master)
    if (isempty(table_handle) && isempty(htol))    % standalone mode requires master to be a protocol XML
        fprintf(2,'ERROR: % s is not a Protocol XML file\n',file);
        return
    end
    [stat,tabd] = zlux_build_tabledata(h,htol);
    if (~stat), return; end
    if (~isempty(table_handle)), set(table_handle, 'Data', tabd, 'Enable', 'on'); end
    
% --- Match against dicom header info and check for protocol match ---
else
    if (~isempty(table_handle))             % GUI calls this way
        tabd = get(table_handle,'Data'); 
    else                                    % standalone this way
        tabd = master_tabd;
    end
    [stat,tabd] = zlux_match_tabledata(h,tabd);
    if (~stat), return; end
    
    if (~isempty(table_handle)), matched = zlux_prot_matched(tabd); 
    else                         [matched,details] = zlux_prot_matched(tabd); end
    
    if (~isempty(table_handle))
        set(table_handle, 'Data', tabd);
        if (matched), set(hmatch,'cdata',greendot);
        else          set(hmatch,'cdata',reddot);    end
    end
end
return

% ------------------------------------------------------------------------
function [stat,tabd] = zlux_build_tabledata(h0,htol)

stat = 0;

% --- Define table data ---
[jprot,jfield,jtype,jval1,jval2,jtol,jmat,ncol] = zlux_getcols();
nrows = numel(h0);
tabd  = cell(nrows,ncol);
for i = 1:nrows
    tabd{i,jfield} = h0(i).tag;
    tabd{i,jtype} = format_type(h0(i));
    tabd{i,jval1} = format_val(h0(i));
    tabd{i,jval2} = '-';

    if (isempty(htol) || isequal(htol(i).value,'off'))
        tabd{i,jprot} = false;    
        tabd{i,jmat}  = false;
        tabd{i,jtol}  = 'exact';
    else
        tabd{i,jprot} = true;    
        tabd{i,jmat}  = false;
        tabd{i,jtol}  = htol(i).value;
    end
end
stat = 1;
return

% ------------------------------------------------------------------------
function [stat,tabd] = zlux_match_tabledata(h1,tabd)

stat = 0;

% --- find matching field names from dicom header and existing table data ---
%[jtype,jval1,jval2,jtol,jmat,jfield,jprot,ncol] = get_colindices(colnames);
[jprot,jfield,jtype,jval1,jval2,jtol,jmat] = zlux_getcols();
tags0 = tabd(:,jfield);
nrows = numel(tags0);
for i=1:nrows, tags0{i} = zlux_set_cellcolor('off',tags0{i}); end % clear hmtl code to color cell
tags1 = {h1(:).tag};
m0    = find_common_fields(tags0,tags1);

% --- Update data match and protocol status ---
for i = 1:nrows
    if (m0(i) ~= 0)         % there is a matching field name in h1
        tabd{i,jval2} = format_val(h1(m0(i)));
    end
    tabd{i,jmat} = zlux_match_vals(tabd{i,jval1}, tabd{i,jval2}, tabd{i,jtype}, tabd{i,jtol});
    if (tabd{i,jprot} == 1)
        if (tabd{i,jmat})     % protocol ON and data matched
            tabd{i,jfield} = zlux_set_cellcolor('#00AA00',tabd{i,jfield});
        else                    % protocol ON and data NOT matched
            tabd{i,jfield} = zlux_set_cellcolor('#CC0000',tabd{i,jfield});
        end
    end
end

stat = 1;
return

% ------------------------------------------------------------------------
function strval = format_type(h)

switch(h.attribs(1).value)
    case '''float'''
        strval = 'float';
    case '''string'''
        strval = 'string';
    otherwise
        error('unrecognized atrribute!');
end

return

% ------------------------------------------------------------------------
function strval = format_val(h)

switch(h.attribs(1).value)
    case '''float'''
        strval = h.value;
    case '''string'''
        strval = h.value;
    otherwise
        error('unrecognized atrribute!');
end
return

% ------------------------------------------------------------------------
function [m0,m1] = find_common_fields(tags0,tags1)

n0 = numel(tags0);
n1 = numel(tags1);

m0 = zeros(n0,1);
m1 = zeros(n1,1);

for i=1:n0
    for j=1:n1
        if (isequal(cstrcmp(tags0{i},tags1{j}),0))
            m0(i) = j;
            m1(j) = i;
            break;
        end
    end
end
return
