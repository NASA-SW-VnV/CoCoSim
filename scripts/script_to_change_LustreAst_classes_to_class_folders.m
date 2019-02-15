classNames = {...
%     'EnumTypeExpr',...
%     'EnumValueExpr',...
%     'EveryExpr',...
%     'IntExpr',...
%     'IteExpr',...
    'LocalPropertyExpr',...
    'LustreAst',...
    'LustreAutomaton',...
    'LustreComment',...
    'LustreContract',...
    'LustreEq',...
    'LustreExpr',...
    'LustreProgram',...
    'LustreVar',...
    'MergeExpr',...
    'NodeCallExpr',...
    'ParenthesesExpr',...
    'RawLustreCode',...
    'RealExpr',...
    'TupleExpr',...
    'UnaryExpr',...
    'VarIdExpr'...
	};
credit = 'Hamza';
%cpRight = 'Khanh';
newFunctionFileName = {...
    %%% common functions
%     'deepCopy'...
%     'simplify',...
%     'nbOccuranceVar',...
%     'substituteVars',...
%     'changePre2Var',...
%     'changeArrowExp',...
%     'pseudoCode2Lustre',...
%     'print(',...
%     'print_lustrec',...
%     'print_kind2',...
%     'print_zustre',...
%     'print_jkind',...
%     'print_prelude'...
%%%%  functions not common
      'getCondsThens',...
      'nestedIteExpr',...
      'listVarsWithDT',...
      'getLustreEq',...
      'isSimpleExpr',...
      'printWithOrder',...
      'uniqueVars',...
      'removeVar',...
      'setDiff',...
      'getArgsStr',...
      'ismemberVar'...      
    };

for cl=1:numel(classNames)
    className = classNames{cl};
    workDir = '/Users/ktrinh/cocosim/cocosim2/src/middleEnd/+nasa_toLustre/+lustreAst';
    cd (workDir);

    dirName = sprintf('@%s',className);
    classFileName = sprintf('%s.m',className);
    tempFileName = sprintf('%s_temp.m',className);
    mvStr = sprintf('git mv %s %s',classFileName,tempFileName);
    %% move original file to file with _temp on git
    %system(mvStr);
    %% mkdir @classname
    %system(sprintf('mkdir %s',dirName));
    cpRight{1} = '    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
    cpRight{2} = '    % Copyright (c) 2017 United States Government as represented by the';
    cpRight{3} = '    % Administrator of the National Aeronautics and Space Administration.';
    cpRight{4} = '    % All Rights Reserved.';
    if strfind(credit,'Hamza')
        cpRight{5} = '    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>';
    else
        cpRight{5} = '    % Author: khanh Trinh <khanh.v.trinh@nasa.gov>';
    end
    cpRight{6} = '    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
    cpRight{7} = ' ';
    % read old class file
    oldclassFileName = fopen(sprintf('%s/%s',workDir,tempFileName),'r');
    tline = fgetl(oldclassFileName);
    tlines = cell(0,1);
    while ischar(tline)
        tlines{end+1,1} = tline;
        tline = fgetl(oldclassFileName);
    end
    fclose(oldclassFileName);

    % search for function signature in oldclassFileName
    functionLines = regexp(tlines,'function','match','once');
    functionLinesMask = ~cellfun(@isempty, functionLines);

    % write function file
    indexFuncBlock2BreplacedSignatureStart = [];
    indexFuncBlock2BreplacedSignatureEnd = [];
    indexFuncBlock2BreplacedEnd = [];
    for i=1:numel(newFunctionFileName)
        % create file
        newFileName = newFunctionFileName{i};
        if strfind(newFileName,'print(')
            newFileName = 'print';
        end
        
        curFunctionFileCreated = 0;
        % search for match of function name among functionlines
        for j = find(functionLinesMask)'
            if strfind(tlines{j},'%% This function is used by')
                continue;
            end
            if strfind(tlines{j},newFunctionFileName{i})
                if ~curFunctionFileCreated
                    functionFile = fopen(sprintf('%s/%s.m',dirName,newFileName),'w');
                    curFunctionFileCreated = 1;
                end
                startIndex = regexp(tlines{j},'function');
                indexFuncBlock2BreplacedSignatureStart(end+1) = j;
                % write 1st line in file which is function signature line            
                str = tlines{j};  
                %newStr = extractAfter(str,startIndex-1);
                newStr = str(startIndex:end);
                fprintf(functionFile,'%s\n',newStr);
                % look for close parenthesis
                foundSignatureEnd = strfind(tlines{j},')');
                lineNumber = j;
                while ~foundSignatureEnd
                    lineNumber = lineNumber + 1;
                    str = tlines{lineNumber};
                    %newStr = extractAfter(str,startIndex-1);
                    newStr = str(startIndex:end);
                    fprintf(functionFile,'%s\n',newStr);fileName2delete
                    foundSignatureEnd = strfind(tlines{lineNumber},')');                
                end
                indexFuncBlock2BreplacedSignatureEnd(end+1) = lineNumber;
                % write copy right
                for k=1:numel(cpRight)
                    fprintf(functionFile,'%s\n',cpRight{k});
                end
                % look for end of function and break out
                for k=lineNumber+1:numel(tlines)
                    str = tlines{k};
                    %newStr = extractAfter(str,startIndex-1);
                    newStr = str(startIndex:end);
                    fprintf(functionFile,'%s\n',newStr);                
                    endIndex = regexp(tlines{k},'end');
                    if endIndex == startIndex
                        indexFuncBlock2BreplacedEnd(end+1) = k;
                        break;
                    end
                end

            end
        end
        if curFunctionFileCreated
            fclose(functionFile);
        end
        
    end

    % open main class file
    mainClassFileName = fopen(sprintf('%s/%s/%s',workDir,dirName,classFileName),'w');
    % modify main class file
    inFunctionToBeReplacedBlock = 0;
    newLine = '';
    for l=1:numel(tlines)
        line2print = sprintf('%s\n',tlines{l});
        for i=1:numel(indexFuncBlock2BreplacedSignatureStart)
            if l==indexFuncBlock2BreplacedSignatureStart(i)
                startIndex = regexp(tlines{l},'function');
                stString = tlines{l}(1:startIndex-1);
                endSring = tlines{l}(startIndex+9:end);
                %newStr = erase(tlines{l},'function ');
                line2print = sprintf('%s%s\n',stString,endSring);
            end

            if l>indexFuncBlock2BreplacedSignatureEnd(i) && l<=indexFuncBlock2BreplacedEnd(i)
                line2print = '';
            end
        end

        if ~isempty(line2print)
            fprintf(mainClassFileName,'%s',line2print);
        end
    end
    fclose(mainClassFileName);
end

