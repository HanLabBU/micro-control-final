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
global movement;
global fi;

fi = 0;
movement = cell(0);
global f;

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
    'Position', [0.35 0.31 0.33 0.05],'string','Experiment output file name',...
    'FontName', 'Wawati SC', 'FontSize', 9);
huiw4 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.25 0.33 0.05],'string','Number of trials?',...
    'FontName', 'Wawati SC', 'FontSize', 9);
huiw5 = uicontrol('Style','edit', 'Units', 'Normalized', ...
    'Position', [0.35 0.19 0.33 0.05],'string','Length of trials? [ms]',...
    'FontName','Wawati SC', 'FontSize',9);
huiw6 = uicontrol('Style','pushbutton', 'Units', 'Normalized', ...
    'Position', [0.35 0.13 0.33 0.05],'string','Stop','CallBack',@callbackfn2,...
    'FontName','Wawati SC', 'FontSize',9);
set(huiw6,'enable','off');
set(f, 'Visible','on');


function callbackfn1(~,~)
    global huiw1;
    global huiw3;
    global huiw4;
    global huiw5;
    global huiw6;
    global huipusha;
    global uart;
    global fi;
    global movement;
    
    fi = fopen(huiw3.String,'w');
    uart = serial(huiw1.String, 'BaudRate', 115200);
    fopen(uart);

    pause(2);

    fwrite(uart,sprintf('%s,%s',huiw4.String, huiw5.String));
    pause(0.1);
    x = fscanf(uart,'%s\n');
    fprintf(x);
    movement = cell(0);
    fprintf('Beginning acquisition\n');
    set(huiw6,'enable','on');
    set(huipusha,'enable','on');

    while true
        movement{end+1} = fscanf(uart,'%s');
        if strcmp(movement{end},'END')
            break;
        end
        fprintf('%s\n',movement{end});
        pause(0.001);
    end
    for i=1:numel(movement)
        fprintf(fi,'%s\n',movement{i});
    end
    fclose(fi);
    set(huiw6,'enable','off');
    set(huipusha,'enable','on');
    fclose(uart);
    delete(uart);
    movement = cell(0);
    clear uart
end

function callbackfn2(~,~)
global uart;

fwrite(uart,"STOP");

end

