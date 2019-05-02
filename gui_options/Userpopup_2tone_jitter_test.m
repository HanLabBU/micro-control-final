    fi = fopen('two_tone_test.txt','w');
    uart = serial('com8', 'BaudRate', 115200);
    fopen(uart);

    pause(2);
    
    fwrite(uart,sprintf('%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',...
        '20000', ... % add in trials/trial length
        '5000', '2', '2',... % jitter/no trials for both
        '10000', '200',... % add in puff/puff length;
        '2000', '800', '8000','0.1',... % tone for fq1
        '2000','0.1'... % tone for fq2
    ));
    
    pause(0.1);
    x = fscanf(uart,'%s\n');
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
    fclose(uart);
    delete(uart);
    
    for m=1:numel(movement)
        if ~strcmp(movement{m},'END')
            fprintf(fi,'%s\n',movement{m});
        end
    end
    fclose(fi); 
    movement = cell(0);
    clear uart
