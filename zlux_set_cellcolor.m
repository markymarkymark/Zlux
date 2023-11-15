% ------------------------------------------------------------------------
function str = zlux_set_cellcolor(color,text)

% --- first strip any previous color string in the input string ---
if (~isempty(strfind(text,'<html>')))
    p0 = strfind(text,'<TD>') + 4;
    p1 = strfind(text,'</TD>') - 1;
    text = text(p0:p1);
end

if (~isequal(color,'off'))
    str = ['<html><table border=0 width=400 bgcolor=',color,'><TR><TD>',text,'</TD></TR> </table></html>'];
else
    str = text;
end
return