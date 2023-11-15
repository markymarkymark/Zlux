% to compile
%
%  mcc -m zlux -a spm_dicom_dict.mat 

function varargout = zlux(varargin)
% ZLUX MATLAB code for ZLUX.fig
%      ZLUX, by itself, creates a new ZLUX or raises the existing
%      singleton*.
%
%      H = ZLUX returns the handle to a new ZLUX or the handle to
%      the existing singleton*.
%
%      ZLUX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ZLUX.M with the given input arguments.
%
%      ZLUX('Property','Value',...) creates a new ZLUX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before zlux_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to zlux_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help zlux

% Last Modified by GUIDE v2.5 24-Feb-2015 15:48:49

% Begin initialization code - DO NOT EDIT
global zlux_init
if (isempty(zlux_init)), zlux_init = true; end  % added by MELLIOTT to handle command line args

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @zlux_OpeningFcn, ...
    'gui_OutputFcn',  @zlux_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~zlux_init   % this prevents initial call with zlux('file1','file2') from being triggering a callback
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
zlux_init = false;
return

% --- Executes just before zlux is made visible.
function zlux_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to zlux (see VARARGIN)

% Choose default command line output for zlux
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes zlux wait for user response (see UIRESUME)
% uiwait(handles.figure1);

zlux_init_gui(handles);
set(hObject,'CloseRequestFcn',@zlux_closegui); % handle user close of GUI

% --- handle possible command line args ---
if (nargin > 3)
    nargs = numel(varargin);
    file1 = '';
    file2 = '';
    if (nargs > 0), file1 = varargin{1}; end
    if (nargs > 1), file2 = varargin{2}; end
    load_files(handles,file1,file2);
end
return

% --- Outputs from this function are returned to the command line.
function varargout = zlux_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
return

% --- Executes on button press in BUTTON_load1.
function BUTTON_load1_Callback(~, eventdata, handles)
% hObject    handle to BUTTON_load1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global zlux_last_path1       % previously selected file path
if (isempty(zlux_last_path1)), zlux_last_path1 = ''; end

% --- Select dicom or protocol file  ---
wildcard   = {'*.dcm;*.DCM;*.IMA','Dicom (*.dcm,*.dcm,*.IMA)'; '*.xml;*.XML','XML (*.xml,*.XML)'};
[file, path] = uigetfile(wildcard,'Select a dicom or protocol file',zlux_last_path1,'MultiSelect','off');
if isequal(file,0)
    return
end
zlux_last_path1 = path;
file1 = [path filesep() file];

load_files(handles,file1,get(handles.TEXT_file2,'String'));
return

% --- Executes on button press in BUTTON_load2.
function BUTTON_load2_Callback(hObject, eventdata, handles)
% hObject    handle to BUTTON_load2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global  zlux_last_path2       % previously selected file path
if (isempty(zlux_last_path2)), zlux_last_path2 = ''; end

% --- Select dicom or protocol file  ---
wildcard   = {'*.dcm;*.DCM;*.IMA','Dicom (*.dcm,*.dcm,*.IMA)'; '*.xml;*.XML','XML (*.xml,*.XML)'};
[file, path] = uigetfile(wildcard,'Select a dicom or XML file',zlux_last_path2,'MultiSelect','off');
if isequal(file,0)
    return
end
zlux_last_path2 = path;
file2 = [path filesep() file];

load_files(handles,get(handles.TEXT_file1,'String'),file2);
return

% --- Executes on button press in BUTTON_save.
function BUTTON_save_Callback(hObject, eventdata, handles)
% hObject    handle to BUTTON_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (isempty(get(handles.TEXT_file1,'String'))), return; end % no protocol loaded

% --- get table data info ---
tabd = get(handles.TABLE1,'Data');
% colnames = get(handles.TABLE1,'ColumnName');
% [jtype,jval1,jval2,jtol,jmat,jfield,jprot] = get_colindices(colnames);
[jprot,jfield,jtype,jval1,~,jtol] = zlux_getcols();
nrows = size(tabd,1);

% --- fill value and tolerance structures of fields in the protocol ---
vstruct = [];
for i=1:nrows
    tag = zlux_set_cellcolor('off',tabd{i,jfield}); % remove any HTML entries for color of cell
    if (isequal(tabd{i,jval1},'##TooLong_IGNORED##')), tabd{i,jtype} = 'string'; end % catch problem with calling this a float
    switch tabd{i,jtype}
        case 'string'
            eval(sprintf('vstruct.%s = ''%s'';',tag,tabd{i,jval1}));
        case 'float'
            eval(sprintf('vstruct.%s = [ %s ];',tag,tabd{i,jval1}));
    end
    if (tabd{i,jprot})
        eval(sprintf('tstruct.%s = ''%s'';',tag,tabd{i,jtol}));
    else
        eval(sprintf('tstruct.%s = ''%s'';',tag,'off'));        
    end
end
if (isempty(vstruct)), fprintf(2,'ERROR: no fields are selected to be in the protocol!\n'); return; end

% --- Save protocl as XML to user chosen file ---
[file, path] = uiputfile({'*.xml;*.XML','XML (*.xml,*.XML)'},'Save protocol as:');
if (isequal(file,0)), return; end
outfile = [path file];
[~,~,ext] = fileparts(outfile);
if (isempty(ext)), outfile = [outfile '.xml']; end

% --- Save protocl as XML to user chosen file ---
[fp,errmess] = fopen(outfile,'w');
if (fp < 0), error(errmess); return; end
fprintf(fp,'<zluxProtocol>\n');
fprintf(fp,'<protVals>\n');
print_structure(fp,vstruct,'',1);
fprintf(fp,'</protVals>\n');
fprintf(fp,'<protTols>\n');
print_structure(fp,tstruct,'',1);
fprintf(fp,'</protTols>\n');
fprintf(fp,'</zluxProtocol>\n');
fclose(fp);

return

% --- Executes on button press in RADIO_protmatch.
function RADIO_protmatch_Callback(hObject, eventdata, handles)
% hObject    handle to RADIO_protmatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RADIO_protmatch



% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function zlux_init_gui(handles)

global hmatch reddot greendot

% --- init global vars ---
set(handles.TEXT_file1,'String','');
set(handles.TEXT_file2,'String','');
hmatch = handles.RADIO_protmatch; % handle to radio button displaying match status

% --- make a red and green light for the prot match radiobutton ---
reddot(:,:,1)=[196 193 190 207 62 86 91 67 212 191 195 201;
    196 206 32 61 166 186 190 166 59 33 205 190;
    199 38 180 209 227 229 232 231 215 179 35 198;
    219 71 215 250 255 255 251 253 252 215 61 210;
    67 169 230 250 255 255 254 255 253 225 167 62;
    87 186 227 255 254 248 255 253 253 227 186 88;
    86 191 227 253 252 255 255 251 252 228 186 86;
    64 166 226 252 255 253 251 254 254 226 168 67;
    219 64 215 254 255 253 252 255 253 213 60 211;
    197 38 176 215 226 231 230 225 214 174 36 194;
    196 206 34 65 169 189 190 163 60 35 207 193;
    199 190 195 210 67 88 86 64 214 195 193 204];

reddot(:,:,2)=[191 191 195 182 0 0 0 0 184 193 191 193;
    190 186 0 0 36 30 30 30 0 0 185 185;
    189 0 37 15 16 7 9 17 17 37 0 194;
    179 0 16 0 4 1 0 0 0 17 0 180;
    0 33 16 0 2 1 0 0 0 15 38 0;
    0 30 7 3 0 0 1 0 0 9 34 0;
    0 36 10 2 0 3 4 0 0 9 31 0;
    0 33 14 1 4 2 0 2 2 14 34 0;
    183 0 17 0 3 0 0 2 0 17 0 181;
    188 0 32 17 13 9 11 12 18 31 0 192;
    190 186 0 0 34 32 36 33 0 0 185 184;
    193 186 195 181 0 0 0 0 183 192 184 193];

reddot(:,:,3) =[197 194 189 177 0 0 0 0 181 190 188 191;
    194 187 0 0 34 31 32 32 0 0 184 182;
    190 0 29 5 9 4 10 17 16 35 0 193;
    180 0 11 0 0 0 0 1 0 16 0 178;
    0 35 18 0 4 3 5 6 2 14 33 0;
    0 33 9 5 2 0 5 3 2 7 29 0;
    0 40 5 0 0 0 1 0 0 7 29 0;
    0 36 10 0 0 0 0 0 1 13 35 0;
    185 0 16 0 0 0 0 4 3 19 0 181;
    189 0 32 16 7 4 9 14 20 33 0 193;
    192 187 0 0 28 27 34 31 0 0 187 187;
    197 187 193 175 0 0 0 0 178 187 185 197];
reddot=uint8(reddot);
greendot(:,:,1) = reddot(:,:,2);
greendot(:,:,2) = reddot(:,:,1);
greendot(:,:,3) = reddot(:,:,3);
greendot=uint8(greendot);
set(hmatch,'Value',1,'cdata',reddot); % protocol not matched

% --- Define the column names and order ---
%zlux_getcols(colname);
[jprot,jfield,jtype,jval1,jval2,jtol,jmat,ncol,colnames] = zlux_getcols();

% --- Column names and formats ---
tolchoice = {'exact','+-1%','+-5%','+-10%','+-1','+-10','+-100','other...'};
%colnames = {'prot',    'Field', 'type',  'val1',  'val2', 'matched', 'tolerance'};
colform  = {'logical', 'char',  'char',  'char',  'char', 'logical',  tolchoice};
coledit  = [true       false    false    false     false  false       true];
colwidth = {'auto'     80       40       40        40     'auto'      'auto'};

% --- make dummy initial table data ---
tabd = cell(1,ncol);
tabd{1,jprot}  = false;
tabd{1,jfield} = '';
tabd{1,jtype}  = '';
tabd{1,jval1}  = '';
tabd{1,jval2}  = '';
tabd{1,jmat}   = false;
tabd{1,jtol}   = 'exact';

% --- Create the uitable ---
set(handles.TABLE1, 'Data', tabd,...
    'ColumnName', colnames,...
    'ColumnFormat', colform,...
    'ColumnEditable', coledit,...
    'RearrangeableColumns', 'on',...
    'Enable', 'off',...
    'CellEditCallback', @celledit_callback, ...
    'RowName',[]);

%    'CellEditCallback', @celledit_callback, ...
%    'CreateFcn', @create_callback, ...
%    'ColumnWidth', colwidth,...

% -- use java handle to column resize issues ---
jScroll = findjobj(handles.TABLE1);
jTable = jScroll.getViewport.getView;
%jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_NEXT_COLUMN);

% --- Turn on column rearranging ---
jTable.setSortable(true);		% or: set(jtable,'Sortable','on');
jTable.setAutoResort(true);
jTable.setMultiColumnSortable(true);
jTable.setPreserveSelectionsAfterSorting(true);


% -------------------------------------------------------------------------
function load_files(handles,file1,file2)

% --- load master file if provided ---
if (~isempty(file1))
    set(handles.TEXT_file1,'String','');
    stat = zlux_loadtable(file1,1,handles.TABLE1);
    if (stat)
        set(handles.TEXT_file1,'String',file1);
    end
end
    
% --- load test file if master already loaded ---
if (~isempty(file2))
    set(handles.TEXT_file2,'String',file2); % store this so we remember it 
    if (~isempty(get(handles.TEXT_file1,'String')))
        set(handles.TEXT_file2,'String','');
        stat = zlux_loadtable(file2,0,handles.TABLE1);
        if (stat)
            set(handles.TEXT_file2,'String',file2);
        end
    end
end

return

% ------------------------------------------------------------------------
function celledit_callback(t, event)

global hmatch reddot greendot

% --- need static variable to handle "use_java" option ---
persistent getgone
if (isempty(getgone)), getgone = 0; end

% --- update table changes using Java ---
% --- this method causes re-call of this callback ---
% --- but it avoids re-drawing whole table and resetting scroll position! ---
use_java = 1;
debug    = 0;

% --- handle double callback issue (see end of this function) ---
% --- need to ignore these extra callbacks ---
if (use_java)
    if (getgone > 0)
        if (debug), fprintf(1,'Entering: getgone = %1d\n',getgone); end
        getgone = getgone - 1;
        return;
    else
        if (debug), fprintf(1,'\nEntering: getgone = %1d\n',getgone); end
    end
end

% --- get info on event ---
row    = event.Indices(1);
col    = event.Indices(2);
tabd   = get(t,'Data');
nrows  = size(tabd,1);
newrow = tabd(row,:);  % this will hold new values of the modified row

% --- get index for each column (in case column order is switched around) ---
% colnames = get(t,'ColumnName');
% [jtype,jval1,jval2,jtol,jmat,jfield,jprot] = get_colindices(colnames);
[jprot,jfield,jtype,jval1,jval2,jtol,jmat,~,colnames] = zlux_getcols();

% --- if using Java, rows mays be sorted differently (i.e. by column) ---
if (use_java)
    jScroll = findjobj(t);
    jTable = jScroll.getViewport.getView;
    fieldname = tabd{row,jfield};
    javarow = -1;
    for i = 1:nrows
        if (isequal(fieldname,jTable.getValueAt(i-1,jfield-1)))
            javarow = i;
            break;
        end
    end
    if (javarow == -1)
        error('cant find java row matching Fieldname %s',fieldname);
    end
end

% --- What property (i.e. Column) was edited ---
switch(colnames{col})
    case 'tolerance'
        % --- strings must always have 'exact' tolerance ---
        if (isequal(tabd{row,jtype},'string'))
            newrow{jtol} = event.PreviousData;
            
            % --- user chose to make customized tolerance ---
        elseif isequal(tabd{row,jtol},'other...')
            newtol = cell2mat(inputdlg('Enter % or absolute value','User Defined Tolerance'));
            if (isempty(newtol))
                newrow{jtol} = event.PreviousData;   % Cancel chosen - reset to last val
            end
            newtol = newtol(~isspace(newtol));       % remove all blank spaces
            if isequal(newtol(end),'%')
                newtol = newtol(1:end-1);            % chop off trailing '%'
                do_percent = 1;
            else
                do_percent = 0;
            end
            if (isempty(str2num(newtol)))
                msgbox('You must enter a number','Error','error');
                tabd{row,jtol} = event.PreviousData;
            else
                newtol = ['+-' newtol];
                if (do_percent), newtol = [newtol '%']; end
                newrow{jtol} = newtol;
                newrow{jmat} = zlux_match_vals(tabd{row,jval1}, tabd{row,jval2}, tabd{row,jtype}, newrow{jtol});
            end
            
            % --- user chose a pre-defined tolerance ---
        else
            newrow{jmat} = zlux_match_vals(tabd{row,jval1}, tabd{row,jval2}, tabd{row,jtype}, newrow{jtol});
        end
        
    case 'prot' % don't actually have to do anything, checkbox is already set by matlab
        
    case 'Field' % This only gets called when the color is changed
        
    otherwise
        error('unrecognized column was edited!');
end

% --- Update Field color to reflect change in match or protocol status ---
if (newrow{jprot} == 1)
    if (newrow{jmat})     % protocol ON and data matched
        newrow{jfield} = zlux_set_cellcolor('#00AA00',tabd{row,jfield});
    else                    % protocol ON and data NOT matched
        newrow{jfield} = zlux_set_cellcolor('#CC0000',tabd{row,jfield});
    end
else                        % protocol OFF
    newrow{jfield} = zlux_set_cellcolor('off',tabd{row,jfield});
end

% --- update data associated with table using Matlab standard method ---
if (~use_java)
    tabd(row,:) = newrow;
    set(t,'Data',tabd);  % this causes Matlab to redraw the whole table, which resets the scrollbars and column widths!
    
    % --- update protocol matched status ---
    if (zlux_prot_matched(tabd)), set(hmatch,'cdata',greendot);
    else                     set(hmatch,'cdata',reddot);    end
    
    % --- Update only individual cells to avoid above problem ---
    % --- Each change made this way will result in another call to this routine which we want to ignore ---
else
    if (~isequal(newrow{jtol},tabd{row,jtol}))
        jTable.setValueAt(java.lang.String(newrow{jtol}), javarow-1,jtol-1); % Java indexes from 0..n-1
        getgone = getgone + 1;
    end
    if (~isequal(newrow{jfield},tabd{row,jfield}))
        jTable.setValueAt(java.lang.String(newrow{jfield}),javarow-1,jfield-1);
        getgone = getgone + 1;
    end
    if (~isequal(newrow{jmat},tabd{row,jmat}))
        jTable.setValueAt(newrow{jmat},javarow-1,jmat-1);
        getgone = getgone + 1;
    end
    
    % --- update protocol matched status ---
    tabd(row,:) = newrow;
    if (zlux_prot_matched(tabd)), set(hmatch,'cdata',greendot);
    else                     set(hmatch,'cdata',reddot);    end
    
    if (debug), fprintf(1,'Leaving: getgone = %1d\n',getgone); end
end
return;

% -----------------------------------------------------------------------
function zlux_closegui(src,callbackdata)

global zlux_init

zlux_init = true;              % reset to handle command line args on first call to zlux()
closereq();                     % run normal GUI close function

return
