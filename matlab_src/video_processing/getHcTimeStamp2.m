function ts = getHcTimeStamp2(info)
 imDes = info.ImageDescription;

[idLines,~] = strsplit(imDes,'\r\n');
tfsLine = idLines{strncmp(' Time_From_Start',idLines,12)};
tfsNum = sscanf(tfsLine,' Time_From_Start = %d:%d:%f');

ts = tfsNum(1)*3600 + tfsNum(2)*60 + tfsNum(3);