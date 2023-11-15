% ------------------------------------------------------------------------
function [match,details] = zlux_prot_matched(tabd)

match   = false;
details = '';

nrows = size(tabd,1);
[jprot,jfield,jtype,jval1,jval2,~,jmat] = zlux_getcols();

% --- at least one field must be selected in protocol ---
if (max([tabd{:,jprot}]) == 0), return; end

% --- if all included fields aren't matched ---
match = true;
for i=1:nrows
    if (tabd{i,jprot} && ~tabd{i,jmat})
        match = false;
        if (nargout < 2)
            return;        % can exit right away with no match
        else
            details = [details sprintf('%-40s\t%-40s\t%-40s\n',zlux_set_cellcolor('off',tabd{i,jfield}),tabd{i,jval1},tabd{i,jval2})];
        end
    end
end
return
