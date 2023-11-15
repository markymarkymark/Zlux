% ------------------------------------------------------------------------
function [jprot,jfield,jtype,jval1,jval2,jtol,jmat,ncol,colnames] = zlux_getcols(set_colnames)

%persistent fixed_colnames

% --- Set the column order and their names ---
fixed_colnames = {'prot' ; 'Field' ; 'type' ; 'val1'; 'val2' ; 'matched' ; 'tolerance'};
% if (nargin > 0)
%     fixed_colnames = set_colnames;
% end
  
%  --- Returned fixed order of columns into table data ---
colnames = fixed_colnames;
jprot  = find(not(cellfun('isempty', strfind(colnames,'prot'))));
jfield = find(not(cellfun('isempty', strfind(colnames,'Field'))));
jtype  = find(not(cellfun('isempty', strfind(colnames,'type'))));
jval1  = find(not(cellfun('isempty', strfind(colnames,'val1'))));
jval2  = find(not(cellfun('isempty', strfind(colnames,'val2'))));
jtol   = find(not(cellfun('isempty', strfind(colnames,'tol'))));
jmat   = find(not(cellfun('isempty', strfind(colnames,'matched'))));
ncol   = numel(colnames);
return
