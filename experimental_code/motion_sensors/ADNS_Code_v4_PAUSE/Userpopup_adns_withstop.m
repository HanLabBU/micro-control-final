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
global stop;
global huipusha;
stop = false;

f = figure('Visible','off','Units','Normalized',...
    'Position', [0.1 0.1 0.4 0.4], 'Color', [0 0.7 0.7],...
    'name', 'Mouseball Setup');
huipusha = uicontrol('Style','pushbutton', 'Units', 'Normalized', ...
    'Position', [0.1 0.5 0.35 0.1],'string','Start', 'Callback', @callbackfn1,...
    'FontName', 'Wawati SC', 'FontSize', 14,'interruptible','on');

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
huiw6 = uicontrol('Style','pushbutton', 'Units', 'Normalized', ...
    'Position', [0.55 0.5 0.35 0.1],'string','Stop', 'Callback', @callbackfn2,...
    'FontName', 'Wawati SC', 'FontSize', 14,'interruptible','on');
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
    global stop;
    global a;
    global fi;

    fi = fopen(huiw3.String,'w');
    try
        uart = serial(huiw1.String, 'BaudRate', 115200);
        fopen(uart);
    catch
        errordlg('There was an error connecting to the USB to Teensy. Please check the COM port.');
    end
    pause(2);

    fwrite(uart,sprintf('%s,%s',huiw4.String, huiw5.String));
    pause(0.1);
    nreps = str2double(fscanf(uart,'%s\n'));
    repcycles = fscanf(uart,'%s\n');
    set(huiw6,'enable','on');
    set(huipusha,'enable','off');
    movement = cell(0);
    fprintf('nreps: %d, repcycles: %s\n',nreps,repcycles);
    fprintf('Beginning acquisition\n');
    pause(0.5);
    for i=1:(nreps+1)
        movement{i} = fscanf(uart,'%s');
        fprintf('%s\n',movement{i});
        pause(0.0001);
        if stop
            break;
        end
    end
    for i=1:numel(movement)
        fprintf(fi,'%s\n',movement{i});
    end
    set(huiw6,'enable','off');
    set(huipusha,'enable','on');
    fclose(fi);
    fclose(uart);
    delete(uart);
    clear uart
    stop = false;
end



function callbackfn2(~,~)
global uart;
global stop;
stop = true;
fwrite(uart,"STOP");

end

