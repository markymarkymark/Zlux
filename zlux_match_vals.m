% ------------------------------------------------------------------------
function stat = zlux_match_vals(v1,v2,type,tolerance)

stat = false;

switch(type)
    case 'string'
        stat = isequal(v1, v2); % strings must match exactly
        
    case 'float'
        if (isequal(v1,'-') || isequal(v2,'-')), return; end % '-' means no entry for this field
        val1 = sscanf(strrep(v1,',',' '),'%f'); % convert comma-separated string to scalar or vector of floats
        val2 = sscanf(strrep(v2,',',' '),'%f');
        if (~isequal(numel(val1),numel(val2))) return; end
        
        switch(tolerance)
            case 'exact'
                stat = isequal(val1,val2);
            otherwise
                tolerance = tolerance(3:end);       % remove '+-' from string
                if (isequal(tolerance(end),'%'))    % toloerance is in %
                    tol = str2num(tolerance(1:end-1))/100;
                else
                    tol = -abs(str2num(tolerance)); % make abs tolerance into negative number
                end
                stat = toltest(val1,val2,tol);
        end
    otherwise
        error('unrecognized atrribute!');
end

return

% ------------------------------------------------------------------------
function stat = toltest(v0,v1,tolerance)

stat = false;

if (tolerance < 0)                  % absolute tolerances are specified with
    diff      = abs(v1-v0);
    tolerance = abs(tolerance);
else
    diff    = abs((v1-v0)./v0);     % relative tolerance
end
maxdiff = max(diff(:));
if (maxdiff <= tolerance), stat = true; end

return
