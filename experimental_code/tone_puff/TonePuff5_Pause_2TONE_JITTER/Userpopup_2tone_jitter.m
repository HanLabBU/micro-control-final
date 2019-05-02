%{
prompt = {'USB to UART Converter Port:', 'Arduino Port:'};
definput = {'i.e. COM1','i.e. COM5');
port = inputdlg(prompt,'Data Ports', [1 15; 1 15],definput);
s = serial('COM5')
%}

global huiw1;
global huiw3;
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
global huiw17;

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
huiw17 = text_input([0.17 0.25 0.33 0.05],'Trial length jitter? [ms]');
huiw5 = text_input([0.17 0.19 0.33 0.05],'Length of trials? [ms]');
huiw10 = text_input([0.5 0.10 0.33 0.05],'CS Tone Trials?');
huiw11 = text_input([0.5 0.03 0.33 0.05],'Neutral Tone Trials?');
    
huiw13 = text_input([0.17 0.13 0.33 0.05],'Puff Start [ms]');
huiw14 = text_input([0.17 0.07 0.33 0.05],'Puff Length [ms]');
    
huiw15 = text_input([0.5 0.52 0.33 0.05], 'CS Tone amp');
huiw9 = text_input([0.5 0.45 0.33 0.05],'CS Tone FQ?');
huiw7 = text_input([0.5 0.38 0.33 0.05],'Tone Start [ms]?');
huiw8 = text_input([0.5 0.31 0.33 0.05],'Tone Length [ms]?');

huiw16 = text_input([0.5 0.24 0.33 0.05], 'Neutral Tone amp');
huiw12 = text_input([0.5 0.17 0.33 0.05],'Neutral Tone FQ?');

huiw6 = uicontrol('Style','pushbutton', 'Units', 'Normalized', ...
    'Position', [0.5 0.7 0.3 0.1],'string','Stop','CallBack',@callbackfn2,...
    'FontName','Wawati SC', 'FontSize',9,'interruptible','on');
set(huiw6,'enable','off');
set(f, 'Visible','on');


function callbackfn1(~,~)
    global huiw1;
    global huiw3;
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
    global huiw17;
    global uart;
    global fi;
    global movement;
    
    toneend =  (str2double(huiw7.String)+str2double(huiw8.String));
    puffend =   (str2double(huiw13.String)+str2double(huiw14.String));
    trialend = str2double(huiw5.String)-str2double(huiw17.String);
    assert(toneend < str2double(huiw13.String)); % tone stops before puff starts
    assert((puffend < (trialend))); % puff stops before trial ends
    assert(str2double(huiw17.String) > 0); % positively valued puff jitter

    fname = [huiw3.String '_' huiw9.String 'Hz1_' huiw15.String 'amp1_' huiw12.String 'Hz2_' huiw16.String 'amp2.txt'];
    
    fi = fopen(fname,'w');
    uart = serial(huiw1.String, 'BaudRate', 115200);
    fopen(uart);

    pause(2);
    
    fwrite(uart,sprintf('%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',...
        huiw5.String, ... % add in trials/trial length
        huiw17.String, huiw10.String, huiw11.String,... % jitter/no trials for both
        huiw13.String, huiw14.String,... % add in puff/puff length;
        huiw7.String, huiw8.String, huiw9.String,huiw15.String,... % tone for fq1
        huiw12.String,huiw16.String... % tone for fq2
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
        if ~strcmp(movement{i},'END')
            fprintf(fi,'%s\n',movement{i});
        end
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

