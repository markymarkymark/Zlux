function stat = print_structure(fp,h,prefix,xml_flag)
% -----------------------------------------------------------------------
% Pretty print a structure's fields
% Uses recursion to print substructures
% Use fp = 1 to print to stdout

stat = 0;

% For recursive calling
if (nargin < 3), prefix = ''; end

% Output in XML format
if (nargin < 4), xml_flag = 0; end

% For formatting output as XML
if (xml_flag)
    delim1 = '<';
    delim2 = '';
    delim3 = '</';
    delim4 = '>';
% or plain text
else
    delim1 = '';
    delim2 = ' = ';
end

% --- Run through all struct fields ---
fields  = fieldnames(h);
nfields = numel(fields);
for i=1:nfields
    sout = sprintf('%s%s%s%s',delim1,prefix,fields{i},delim2);
    val  = getfield(h,fields{i});
    nval = numel(val);

    % --- Empty strings ---
%    if (nval == 0) % ignore
    
    % --- TWIX MAP OBJECT  ---
%    elseif (isequal(class(val),'twix_map_obj')) % ignore
    if (isequal(class(val),'twix_map_obj')) % ignore
          
    % --- STRUCTURES - use recursive call to this routine ---
    elseif (isstruct(val))
        substruct = h.(fields{i});
        status    = print_structure(fp,substruct,[prefix fields{i} '.'],xml_flag);
        if (status == 0), return; end

    % --- NUMBERs or STRINGs ---   
%    elseif (isnumeric(val) || islogical(val)) || (ischar(val) || isstring(val))
    elseif (nval == 0 || isnumeric(val) || islogical(val)) || (ischar(val) || isstring(val))
        sout = print_vals(val,sout,xml_flag);
        if (xml_flag), sout = [sout sprintf('%s%s%s%s',delim3,prefix,fields{i},delim4)]; end
        sout = strrep(sout,'\','\\'); % handle problem with Windows file paths
        fprintf(fp,[sout '\n']);
    
    % --- CELLS - a royal pain ---
    elseif (iscell(val))
        % if (isempty(val{1})); 
        %     break; end
        switch class(val{1})
            case 'struct'
                for j=1:nval
                    if (nval == 1), subfield = sprintf('%s',     fields{i});
                    else            subfield = sprintf('%s_%03d',fields{i},j); end
                    substruct = h.(fields{i}){j};
                    if (~isempty(substruct))
                        status    = print_structure(fp,substruct,[prefix subfield '.'],xml_flag); % recursively call w/ sub-struct
                        if (status == 0), return; end
                    end
                end
            case {'double'}
                dvals=cell2mat(val);
                sout = print_vals(dvals,sout,xml_flag);
                if (xml_flag), sout = [sout sprintf('%s%s%s%s',delim3,prefix,subfield,delim4)]; end
                fprintf(fp,[sout '\n']);
            case {'char'}
                cvals=cell2mat(val);
                sout = print_vals(cvals,sout,xml_flag);
                if (xml_flag), sout = [sout sprintf('%s%s%s%s',delim3,prefix,subfield,delim4)]; end
                fprintf(fp,[sout '\n']);
            otherwise
                fprintf(2,'ERROR: Cannot handle cell type: %s\n',class(val{1}));
                return
        end
        
    % --- Unknown object! ---
    else
        fprintf(2,'ERROR: Unknown field type: %s\n',fields{i});
        return
    end
end

stat = 1;
return

% -----------------------------------------------------------------------
function sout = print_vals(val,sout,xml_flag)
nval = numel(val);

% --- Empty ---
if ((nval == 0) && ~ischar(val) && ~isnumeric(val))
    sout = [sout '[]'];

% --- NUMBERS ---
elseif (isnumeric(val) || islogical(val))
    if (xml_flag)
        sout = [sout ' type=''float'''];
        if (nval > 1), sout = [sout ' delimiter='',''']; end
        sout = [sout '>'];
    end
    if (nval == 0)
        sout = [sout sprintf('%g',NaN)];
    elseif (nval > 100)
        sout = [sout '##TooLong_IGNORED##'];
    else
        sout = [sout sprintf('%g',val(1))];
        if (nval > 1)
            sout = [sout sprintf(', %g',val(2:nval))];
        end
    end
    
% --- STRINGS ---
elseif (ischar(val) || isstring(val))
    if (isstring(val)), val = char(val); end
    if (xml_flag), sout = [sout ' type=''string''>']; end
    if (nval == 0)
        sout = [sout ''''''];
    elseif (nval > 200)
        sout = [sout '##TooLong_IGNORED##'];
    else
        nrows = size(val,1);
        if (nrows > 1)
            for j=1:nrows-1
                line = strtrim(val(j,:)); % removing leading and trailing white space
                line = line(line ~= 0);   % need to remove "null" characters!
                sout = [sout line '\'];
            end
            line = strtrim(val(nrows,:)); % removing leading and trailing white space
            line = line(line ~= 0);       % need to remove "null" characters!
            sout = [sout line];
        else
            line = strtrim(val);          % removing leading and trailing white space
            line = line(line ~= 0);       % need to remove "null" characters!
            sout = [sout line];
        end
    end
end
return
