function varargout = extraction(varargin)
% EXTRACTION MATLAB code for extraction.fig
%      EXTRACTION, by itself, creates a new EXTRACTION or raises the existing
%      singleton*.
%
%      H = EXTRACTION returns the handle to a new EXTRACTION or the handle to
%      the existing singleton*.
%
%      EXTRACTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EXTRACTION.M with the given input arguments.
%
%      EXTRACTION('Property','Value',...) creates a new EXTRACTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before extraction_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to extraction_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help extraction

% Last Modified by GUIDE v2.5 14-Dec-2022 09:39:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @extraction_OpeningFcn, ...
                   'gui_OutputFcn',  @extraction_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before extraction is made visible.
function extraction_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to extraction (see VARARGIN)

% Choose default command line output for extraction
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes extraction wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = extraction_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global embeddedImg;
% [filename, path]=uigetfile();
% fullfilename=strcat(path,filename);
% image=imread(fullfilename);
image=embeddedImg;

handles.image = image;%handle is used further to get image
guidata(hObject, handles);%save in guide so we can use in otherpush button
axes( handles.axes1);
imshow(image);
%  title('Embedded Image')


% --- Executes on button press in dewatermark.
function dewatermark_Callback(hObject, eventdata, handles)
% hObject    handle to dewatermark (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global HashCodeExtracted;
global embeddedImg;
%if isfield(handles, 'image')%get image from guiddata
    %embeddedImg=handles.image;
     [rows,cols]=size(embeddedImg);

Binary=zeros(rows,cols);
Binary=string(Binary);
nImg=embeddedImg;
for i=1:1:rows
    for j=1:1:cols
        Binary(i,j)=dec2bin(embeddedImg(i,j),8);
        k=char(Binary(i,j));
        k(1,8)='0';
        Binary(i,j)=k;
        nImg(i,j)=bin2dec(Binary(i,j));
    end
end

hashExtracted=DataHash(nImg);
disp(hashExtracted);
disp(HashCodeExtracted);
if(HashCodeExtracted==hashExtracted)
     f = msgbox('fergile water marking not compromised', 'Result','result');
  else
       f = msgbox('fergile water marking is compromised', 'Result','result');
  end
% else
%        f = msgbox('Embedded image is not added', 'Error','error');
% end

    


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in extraction.
function extraction_Callback(hObject, eventdata, handles)
% hObject    handle to extraction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 global pseudoRandom;
global HashCodeExtracted;
if isfield(handles, 'image')%get image from guiddata
    embeddedImg=handles.image;
     
img=embeddedImg;
EmbeddedVectorExtraction=zeros(1,12544);

img=embeddedImg;
%img=rgb2gray(img);
[T,EM]=graythresh(img);
imgcpy1=img;
imgcpy1 = padarray(imgcpy1,[1 1],0,'both');

Thresh=uint8(T*255);

[row,col]=size(img);

for i=1:1:row
    for j=1:1:col
        if imgcpy1(i,j)>Thresh
            imgcpy1(i,j)=255;
        end
            
    end
end
imgcpy1=im2double(imgcpy1);
J=regiongrowing(imgcpy1,1,1);
nImg=imgcpy1-J;
counter=0;
for i=1:1:row
    for j=1:1:col
        if nImg(i,j)<0
            nImg(i,j)=255;
        end
    end
end

counter=1;
for i=1:1:row
    for j=1:1:col
        if counter<=12544
            if nImg(i,j)==255
                k=char(dec2bin(img(i,j),8));
                EmbeddedVectorExtraction(1,counter)=str2double(k(1,8));
                counter=counter+1;
            end
        end
    end
end
EmbeddedVectorOriginalOutcome=xor(EmbeddedVectorExtraction,pseudoRandom);

% Watermark Logo Construction

counter=1;
logoExtraction=zeros(64,64);
for i=1:1:64
    for j=1:1:64
        logoExtraction(i,j)=EmbeddedVectorOriginalOutcome(1,counter);
        counter=counter+1;
    end
end
axes( handles.axes2);
imshow( logoExtraction);
% Watermark Text Construction
str='';
RecordExtraction=zeros(1,1024);
for i=1:1:1024
    for j=1:1:8
        str1=string(double(EmbeddedVectorOriginalOutcome(1,counter)));
        str=strcat(str,str1);
        counter=counter+1;
    end
    RecordExtraction(1,i)=bin2dec(str);
    str='';
end


ASCIISec='';
for i=1:1:1024
    if RecordExtraction(1,i) ==0
        break;
    else
        ASCIISec=[ASCIISec,char(RecordExtraction(1,i))];        
    end
end
h=msgbox( ASCIISec);
% Hash Extraction

str='';
HashExtraction=zeros(1,32);
for i=1:1:32
    for j=1:1:8
        str1=string(double(EmbeddedVectorOriginalOutcome(1,counter)));
        str=strcat(str,str1);
        counter=counter+1;
    end
    HashExtraction(1,i)=bin2dec(str);
    str='';
end
HashCodeExtracted='';
for i=1:1:32
    HashCodeExtracted=[HashCodeExtracted,char(HashExtraction(1,i))]; 
    
end
 else
       f = msgbox('Embedded image is not added', 'Error','error');
end


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
image1 = 'recovered image 2.jpg';
axes( handles.axes3);
imshow(image1);
