function [h,h2] = zlux_readxml(xmlfile,sortflag)
% ------------------------------------------------------------------------

h  = [];
h2 = [];
if (nargin < 2), sortflag = 0; end

% --- read the xml file ---
xml = xmltools(xmlfile);
if (isempty(xml)), fprintf(2,'ERROR reading XML file!\n'); return; end

% --- Read in XML made from dicom header or zlux protocol ---
switch(xml.child.tag)
    case 'DCMSEQUENCE'
        h = xml.child.child;
        n = numel(h);
        h = h(n).child;
        n = numel(h);
        tags={h(:).tag};
        if (sortflag)
            [~,idx]=sort(tags);
            h = h(idx);
        end
        
    case 'ZLUXPROTOCOL'
        h  = xml.child.child(1).child; % protocol field names and values
        h2 = xml.child.child(2).child; % protocol field names and tolerances
        
    case 'DLUXPROTOCOL'
        h  = xml.child.child(1).child; % protocol field names and values
        h2 = xml.child.child(2).child; % protocol field names and tolerances
        
    otherwise
        fprintf(2,'ERROR: File is not from a Dicom Sequence or Zlux Protocol!\n');
        return;
end
return
