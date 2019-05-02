%{
prompt = {'USB to UART Converter Port:', 'Arduino Port:'};
definput = {'i.e. COM1','i.e. COM5');
port = inputdlg(prompt,'Data Ports', [1 15; 1 15],definput);
s = serial('COM5')
%}

global huiw1;
global huiw3;
global huiw4;
global huiw5;
global huiw6;
global huiw7;
global huiw8;
global huiw9;
global huiw10;
global huiw11;
global huiw12;
global huiw13;
global huiw14;
global huiw15;
global huiw16;
global movement;
global fi;

fi = 0;
movement = cell(0);
global f;

f = figure('Visible','off','Units','Normalized',...
    'Position', [0.1 0.1 0.4 0.4], 'Color', [0 0.7 0.7],...
    'name', 'Mouseball Setup');
huipusha = uicontrol('Style','pushbutton', 'Units', 'Normalized', ...
    'Position', [0.2 0.7 0.3 0.1],'string','Start', 'Callback', @callbackfn1,...
    'FontName', 'Wawati SC', 'FontSize', 14,'interruptible','on');

text_input = @(position, text) uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', position,'string',text,...
    'FontName', 'Wawati SC', 'FontSize', 9);

huiw1 = text_input([0.17 0.38 0.33 0.05],'Enter the Teensy Serial Port (i.e COM1)');
huiw3 = text_input([0.17 0.31 0.33 0.05],'Experiment output file name');
huiw4 = text_input([0.17 0.25 0.33 0.05],'Number of trials?');
huiw5 = text_input([0.17 0.19 0.33 0.05],'Length of trials? [us]');
huiw13 = text_input([0.17 0.13 0.33 0.05],'Puff Start [us]');
huiw14 = text_input([0.17 0.07 0.33 0.05],'Puff Length [us]');

huiw15 = text_input([0.5 0.52 0.33 0.05], 'Tone 1 amp');
huiw9 = text_input([0.5 0.45 0.33 0.05],'Tone 1 FQ?');
huiw7 = text_input([0.5 0.38 0.33 0.05],'Tone 1 Start [us]?');
huiw8 = text_input([0.5 0.31 0.33 0.05],'Tone 1 Length [us]?');


huiw16 = text_input([0.5 0.24 0.33 0.05], 'Tone 2 amp');
huiw12 = text_input([0.5 0.17 0.33 0.05],'Tone 2 FQ?');
huiw10 = text_input([0.5 0.10 0.33 0.05],'Tone 2 Start [us]?');
huiw11 = text_input([0.5 0.03 0.33 0.05],'Tone 2 Length [us]?');

huiw6 = uicontrol('Style','pushbutton', 'Units', 'Normalized', ...
    'Position', [0.5 0.7 0.3 0.1],'string','Stop','CallBack',@callbackfn2,...
    'FontName','Wawati SC', 'FontSize',9,'interruptible','on');
set(huiw6,'enable','off');
set(f, 'Visible','on');


function callbackfn1(~,~)
    global huiw1;
    global huiw3;
    global huiw4;
    global huiw5;
    global huiw6;
    global huiw7;
    global huiw8;
    global huiw9;
    global huiw10;
    global huiw11;
    global huiw12;
    global huiw13;
    global huiw14;
    global huiw15;
    global huiw16;
    global uart;
    global fi;
    global movement;
    
    tone1end =  (str2double(huiw7.String)+str2double(huiw8.String));
    puffend =   (str2double(huiw13.String)+str2double(huiw14.String));
    tone2end =  (str2double(huiw10.String)+str2double(huiw11.String));
    assert(tone1end < str2double(huiw10.String));
    assert(str2double(huiw13.String) > tone2end);
    assert((puffend < str2double(huiw5.String)));
    
    fname = [huiw3.String '_' huiw9.String 'Hz1_' huiw15.String 'amp1_' huiw12.String 'Hz2_' huiw16.String 'amp2.txt'];
    
    fi = fopen(fname,'w');
    uart = serial(huiw1.String, 'BaudRate', 115200);
    fopen(uart);

    pause(2);
    
    fwrite(uart,sprintf('%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',...
        huiw4.String, huiw5.String, ... % add in trials/trial length
        huiw13.String, huiw14.String,... % add in puff/puff length;
        huiw7.String, huiw8.String, huiw9.String,huiw15.String,... % tone for fq1
        huiw10.String, huiw11.String, huiw12.String,huiw16.String... % tone for fq2
    ));
    
    pause(0.1);
    x = fscanf(uart,'%s\n');
    set(huiw6,'enable','on');
    drawnow
    fprintf(x);
    movement = cell(0);
    fprintf('\nBeginning acquisition\n');
    while true
        movement{end+1} = fscanf(uart,'%s');
        if strcmp(movement{end},'END')
            break;
        end
        fprintf('%s\n',movement{end});
        pause(0.0001);
    end
    for i=1:numel(movement)
        fprintf(fi,'%s\n',movement{i});
    end
    fclose(fi);
    set(huiw6,'enable','off');
    fclose(uart);
    delete(uart);
    movement = cell(0);
    clear uart
end

function callbackfn2(~,~)
global uart;

fwrite(uart,"STOP");

end

