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
global movement;

f = figure('Visible','off','Units','Normalized',...
    'Position', [0.1 0.1 0.4 0.4], 'Color', [0 0.7 0.7],...
    'name', 'Mouseball Setup');
huipusha = uicontrol('Style','pushbutton', 'Units', 'Normalized', ...
    'Position', [0.3 0.5 0.4 0.1],'string','Start', 'Callback', @callbackfn1,...
    'FontName', 'Wawati SC', 'FontSize', 14);

huiw1 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.43 0.33 0.05],'string','Enter the Teensy Serial Port (i.e COM1)',...
    'FontName', 'Wawati SC', 'FontSize', 9);
huiw3 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.31 0.33 0.05],'string','Motor output file name',...
    'FontName', 'Wawati SC', 'FontSize', 9);
huiw4 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.25 0.33 0.05],'string','Length of session? [min]',...
    'FontName', 'Wawati SC', 'FontSize', 9);
huiw5 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.19 0.33 0.05],'string','Sampling interval? [ms]',...
    'FontName','Wawati SC', 'FontSize',9);

huiw6 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.13 0.33 0.05],'string','Water mean spacing? [s]',...
    'FontName','Wawati SC', 'FontSize',9);

huiw7 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.07 0.33 0.05],'string','Water jitter? [s]',...
    'FontName','Wawati SC', 'FontSize',9);



set(f, 'Visible','on');


function callbackfn1(~,~)
    s = instrfind;
    if ~isempty(s)
        fclose(s);
        delete(s);
        clear s;
    end

    global huiw1;
    global huiw3;
    global huiw4;
    global huiw5;
    global huiw6;
    global huiw7;
    global uart;
    global a;
    global fi;
    global movement;
    
    fi = fopen([huiw3.String '_' huiw4.String '_' huiw5.String '_' huiw6.String '_' huiw7.String '_' date '.txt'],'w');
    uart = serial(huiw1.String, 'BaudRate', 115200);
    fopen(uart);

    pause(2);

    fwrite(uart,sprintf('%s,%s,%s,%s',huiw4.String, huiw5.String, huiw6.String, huiw7.String));
    pause(0.1);
    nreps = str2double(fscanf(uart,'%s\n'));
    repcycles = fscanf(uart,'%s\n');
    water_jitter = fscanf(uart,'%s\n');
    water_spacing = fscanf(uart,'%s\n');
    
    movement = cell(nreps,1);
    fprintf('nreps: %d, repcycles: %s, water offset: %s, water jitter: %s\n',nreps,repcycles,water_spacing, water_jitter);
    fprintf('Beginning acquisition\n');
    pause(0.5);
    for i=1:(nreps+1)
        movement{i} = fscanf(uart,'%s');
        fprintf('%s\n',movement{i});
    end
    for i=1:(nreps+1)
        fprintf(fi,'%s\n',movement{i});
    end
    fclose(fi);
    fclose(uart);
    delete(uart);
    clear uart
end
