
function varargout = Metermeter2(varargin)
% METERMETER2 MATLAB code for Metermeter2.fig
%      METERMETER2, by itself, creates a new METERMETER2 or raises the existing
%      singleton*.
%
%      H = METERMETER2 returns the handle to a new METERMETER2 or the handle to
%      the existing singleton*.
%
%      METERMETER2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in METERMETER2.M with the given input arguments.
%
%      METERMETER2('Property','Value',...) creates a new METERMETER2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Metermeter2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Metermeter2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Metermeter2

% Last Modified by GUIDE v2.5 27-Sep-2018 15:57:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Metermeter2_OpeningFcn, ...
                   'gui_OutputFcn',  @Metermeter2_OutputFcn, ...
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

function Metermeter2_OpeningFcn(hObject, eventdata, handles, varargin)

%Color definitions for iterative plotting
handles.colorcell = {'b', 'r','g', 'k', 'm', 'c', 'y', 'b', 'r','g', 'k', 'm', 'c', 'y'};
handles.symbolcell ={'s','o', 'x',  '+', '*', 's','o', 'x',  '+', '*', 's','o', 'x',  '+', '*'};

%Format axis
axes(handles.axes1)
set(gca, 'Box', 'off', 'TickDir', 'out', 'LineWidth', 1, 'FontSize', 10)

%Default values for selection boxes
set(handles.radio_SylsGaps,'Value',0);
set(handles.radio_SylNGap,'Value',1);
set(handles.popup_tempSelect,'Value',1);

% Choose default command line output for Metermeter2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

function varargout = Metermeter2_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Common functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dateVect,hourVect] = extractTimeVects(filenames)
%Extract the date and hour from the filenames
if iscellstr(filenames)
    rendNum = size(filenames,2);
else
    rendNum = size(filenames,1);
end

for i = 1:rendNum
    sp{i} = regexp(filenames{i},'_','split');
    dateVect(i) = datenum([sp{i}{3} '-' sp{i}{4} '-' sp{i}{5}], 'yyyy-mm-dd');
    hourVect(i) = str2num(sp{i}{6}) + ((str2num(sp{i}{7}) + (str2num(sp{i}{8}(1:2))/60)) /60);
end

function IntMat = extractIntervals(p, q, templatesyllBreaks)
%Get template break points
a = transpose(templatesyllBreaks);
a = a(:);

%Interval Durations from the paths and template files
rendNum = length(p);
IntMat = [];
for i = 1:rendNum
    %Rover rendition path and rendition length
    path = [p{i},q{i}];
    
    %Calculate intervals and add to the stack
    [warpedOut] = getWarpedStarts(path,a(:));
    IntMat = [IntMat; diff(warpedOut)'];
end

function parseNames = updateParseNames(handles)
%Determine the number of datasets in list
if iscell(handles.datasetFilename)
    numDatasets = size(handles.datasetFilename,2);
else
    numDatasets = size(handles.datasetFilename,1);
end

%Parse out the datasets
s = 1;
parseNames = [];
tm = str2num(get(handles.edit_parseTimes,'String'));
for i = 1:numDatasets
    sp = regexp(handles.datatitles{i}, '_', 'split');
%     nm = [sp{1} '_' sp{2}];
    nm = sp{2};
    
    %Unpack the parsed data using the 
    for j = 1:size(tm,1);
        %Set Name       
        parseNames{s} = [nm ' @ ' num2str(tm(j,1))];
        
        %Update the pointer
        s = s + 1;
    end
end

function pData = parseData(handles)

%Determine the number of datasets in list
numDatasets = numel(handles.datasetFilename);

%Parse out the datasets
s = 1;
pData = [];
for i = 1:numDatasets
    %Generate parsing indices according to user selections
    subIndices = parseIndices(handles, i);

    %Unpack the parsed data using the 
    for j = 1:size(subIndices,1);
        %Generate the index
        idx = subIndices(j,1):subIndices(j,2);
        
        %Apply index
        pData(s).intervals = handles.dataset(i).intervals(idx,:);
        pData(s).filenames = handles.dataset(i).renditionFilenames(idx);
        pData(s).date = handles.dataset(i).dateVect(idx);
        pData(s).time = handles.dataset(i).timeVect(idx);
        
        %If audio data hasn't been excluded, grab that shit too.
        if ~get(handles.check_tempOnly, 'Value')
            pData(s).audio = handles.dataset(i).audio(idx);
            pData(s).templatesyllBreaks = handles.dataset(i).templatesyllBreaks;
            pData(s).p = handles.dataset(i).p(idx);
            pData(s).q = handles.dataset(i).q(idx);
        end
        
        %Update the pointer
        s = s + 1;
    end
end

function subIndices = parseIndices(handles, idx)
%Get parsing paramters from GUI controls
parseRange = str2num(get(handles.edit_parseTimes,'String'));
parseNum = str2num(get(handles.edit_numMotifs,'String'));

%Cycle through each bin and generate file index
[numBins, ~] = size(parseRange);
subIndices = [];
for i = 1:numBins;
    %Raw index
    Indx = find(handles.dataset(idx).timeVect >= parseRange(i,1) & handles.dataset(idx).timeVect <= parseRange(i,2));
    
    if ~isempty(Indx)
        %Reduce to desired rend num
        if parseNum == -1
            pIndx = Indx;
        else
            if length(Indx) > parseNum
                pIndx = Indx(1:parseNum);
            else
                pIndx = Indx;
            end
        end
        pnts = [pIndx(1), pIndx(end)];
    else
        pnts = [];
    end
    
    %Add to the stack
    subIndices = [subIndices; pnts];
end

function sylSnips = extractSyllables(handles, data, idx)
%Input var is the output of the pData function for a single time bin. Take this and turn it into an array that contains
%the snips of audio corresponding to individual syllables

%Amplify and filter the audio, as selected
audio = Prep(handles,data.audio, idx);

%Get number of songs to process
numRend = numel(data.audio);
sc = 44.15;
sylSnips = [];

%Cycle through each of the renditions, snipping audio as you go
for i = 1:numRend
    %Calculate the starting position for each snip
    pnts = getWarpedStarts([data.p{i}, data.q{i}], data.templatesyllBreaks);
    pntsFS = round(sc.*pnts); %convert ms to samps
    
    %Parse out the snips
    rst = [];
    for j = 1:size(pntsFS,1)
        rst{j} = audio{i}(pntsFS(j,1):pntsFS(j,2));
    end
    sylSnips = [sylSnips; rst];
end

function dataOut = normData(ind, dataIn)
[~, n] = size(dataIn);

for i = 1:n
    dataOut(:,i) = dataIn(:,i)./mean(dataIn(ind,i));
end

function handles = formatAxis(handles, legInfo)
%Standardize formatting of the main output axes
fS = 11;
set(gca, 'Box', 'off', 'TickDir', 'out', 'LineWidth', 1.5, 'FontSize', fS)
% xlabel('FontSize', fS)
% ylabel('FontSize', fS)
% title('FontSize', fS);
legend(legInfo, [225,75,10,5], 'Orientation', 'horizontal'); legend('boxoff')

function handles = plotVarComp(handles)

%Get the intervals to plot
ints = get(handles.listbox_varIntSelect, 'Value');

%Get the parameter to load and covert into varName and column
param = get(handles.popup_varPSelect, 'Value');
if param ==1
    varName = 'W'; col = 1;
elseif param ==2
    varName = 'W'; col = 2;
elseif param ==3
    varName = 'psi'; col = 1;
elseif param ==4
    varName = 'sigma'; col = 1;
end

%Retrieve selected parameters from the model structure
sel = getStructField(handles.varComp.modelstrct, varName);
if param == 1 || param == 2
    selStrip = squeeze(sel(:, :, col));
else
    selStrip = sel;
end

%Plot output
if get(handles.check_exportPlot, 'Value')
    figure;
else
    axes(handles.axes1);
end
cla; hold on

%Get zeroDay for plotting
zeroDay = datenum(get(handles.edit_zeroDay, 'String'), 'mm/dd/yy');
leg = [];

%If selected, plot individual intervals
if get(handles.check_showVarInts, 'Value')
    for i = 1:numel(ints)
        %Plot the output per syllable
        plot(handles.varComp.dt-zeroDay, selStrip(:,ints(i)), [':' handles.symbolcell{i} handles.colorcell{i}], 'LineWidth', 1.5)
    end
    leg = [leg, handles.sgLabels(ints)];
end

%If selected, plot mean over gap intervals
a = 1:numel(handles.sgLabels);
if get(handles.check_mGaps, 'Value')
    %Only take the mean of the gaps that are selected by the user
    ind = ismember(ints, a(2:2:end));
    mParam = mean(selStrip(:,ints(ind)), 2)';
    sParam = std(selStrip(:,ints(ind)), 0, 2)';
    
    %Plot to axis with the heavy weight and unique marker
    shadedErrorBar(handles.varComp.dt-zeroDay, mParam, sParam, 'k', 1)
    leg = [leg; {'mGap'}];
end

if get(handles.check_mVarSyls, 'Value')
    %Only take the mean of the gaps that are selected by the user
    ind = ismember(ints, a(1:2:end));
    mParam = mean(selStrip(:,ints(ind)), 2)';
    sParam = std(selStrip(:,ints(ind)), 0, 2)';
    
    %Plot to axis with the heavy weight and unique marker
%     plot(handles.varComp.dt-zeroDay, mParam, ['-' 'h' 'k'], 'LineWidth', 3);
    shadedErrorBar(handles.varComp.dt-zeroDay, mParam, sParam, 'b', 1)
    leg = [leg; {'mSyl'}];
end

axis auto
handles = formatAxis(handles, leg);
xlabel('Time (Days)')
ylabel('Param (ms)')
title('Variance Decomposition');
hold off

function handles = plotSimAnalysis(handles)
%Get the intervals to plot
ints = get(handles.listbox_simIntSelect, 'Value');

%Retrieve selected parameters from the model structure
score = getStructField(handles.simAnalysis, 'accScores', 1);
days = getStructField(handles.simAnalysis, 'dt');

%Convert to variability, if selected
if false
    scores = (1-score)./(1-0.5);
%     scores = (1-score);

else
    scores = score;
end


%Plot output
if get(handles.check_exportPlot, 'Value')
    figure;
else
    axes(handles.axes1);
end
cla; hold on

%Get zeroDay for plotting
zeroDay = datenum(get(handles.edit_zeroDay, 'String'), 'mm/dd/yy');
leg = [];

%If selected, plot individual intervals
if get(handles.check_showSimInts, 'Value')
    for i = 1:numel(ints)
        %Calc descriptive stats for each syllable
        mSyl = squeeze(nanmean(scores(:,:,ints(i)), 2));
        sSyl  = squeeze(nanstd(scores(:,:,ints(i)), 1, 2));
        
        %Plot the output per syllable
        errorbar(days-zeroDay, mSyl, sSyl, [':' handles.symbolcell{i} handles.colorcell{i}], 'LineWidth', 1.5)
    end
    leg = [leg, handles.sLabels(ints)];
end


% if ~get(handles.check_showSimInts, 'Value')
%     for i = 1:numel(ints)
%         %Calc descriptive stats for each syllable
% %         mSyl = squeeze(nanmean(scores(:,:,ints(i)), 2));
% %         sSyl  = squeeze(nanstd(scores(:,:,ints(i)), 1, 2));
%         s = scores(:,:,ints(i));
%         d = days.*(ones(size(s)));
%         
%         %Plot the output per syllable
%         scatter(d, s, ['.' handles.colorcell{i}])
% %         scatter(days-zeroDay, mSyl,  [':' handles.symbolcell{i} handles.colorcell{i}], 'LineWidth', 1.5)
%     end
%     leg = [leg, handles.sLabels(ints)];
%     
% end

%If selected, plot mean over gap intervals
if get(handles.check_mSimSyls, 'Value')
    %Only take the mean of the syllables that are selected by the user
    mParam = mean((nanmean(scores(:,:,ints), 2)), 3);
    sParam = std((nanmean(scores(:,:,ints), 2)), 1, 3);
    
    %Plot to axis with the heavy weight and unique marker
    shadedErrorBar(days-zeroDay, mParam, sParam, 'k', 1)
    leg = [leg; {'mSyl'}];
end

axis auto
handles = formatAxis(handles, leg);
xlabel('Time (Days)')
ylabel('Variability (ADU)')
title('SAP Variability');
hold off

function out = normSignal(in)
%Normalize the input signal so the RMS = 1

rms = sqrt(mean(in.^2));

out = in./rms;

function filtAudio = Prep(handles,audio,idx)
%Constants for Bandpass Audio (300-6500kHz)
gain = handles.prep.gain(idx);
hp = handles.prep.hp(idx);
lp = handles.prep.lp(idx);

HP_fNorm = hp/(44150/2);
LP_fNorm = lp/(44150/2);
[BP_b,BP_a] = butter(4,[HP_fNorm LP_fNorm]);

if get(handles.check_rms, 'Value')
    audio = cellfun(@(x) normSignal(x), audio, 'UniformOutput', 0);
end

filtAudio = cellfun(@(x) filtfilt(BP_b, BP_a, gain*(x-mean(x))), audio, 'UniformOutput', 0);

function [dt, means, stds] = tempSimple(pData, intType)
%Do the stats on the parsed data
numBins = length(pData);
for i = 1:numBins
    
    if ~intType %(Syl+Gap)
       %Combine syllable and the following gap 
       ints = [];
       numInts = size(pData(i).intervals,2);
       rm = 1:2:numInts;
       idx = 1;
       for j = rm(1:end-1)
          ints(:,idx) = pData(i).intervals(:,j)+pData(i).intervals(:,j+1);
          idx = idx+1;
       end
       ints(:,idx) = pData(i).intervals(:,end);
       
       
       %sum stats
        means(i,:) = mean(ints,1);
        stds(i,:) = std(ints,1,1);
        
    else %Syl and Gap
        %sum stats
        means(i,:) = mean(pData(i).intervals,1);
        stds(i,:) = std(pData(i).intervals,1,1);

    end
    
    %Calc/format timepoints
    dt(i) = mean(pData(i).date',1) + mean(pData(i).time',1)/24;    

end

function [dt, int_out, indx] = tempAll(pData, intType)
%Plot all of the intervals as scatter plot
numBins = length(pData);
int_out = [];
dt = [];

for i = 1:numBins
    len = size(pData(i).intervals,1);
    indx{i} = (size(int_out,1)+1):(size(int_out,1)+len);
    
    %Fix the syl/gap issue
    int = [];
    if ~intType %(Syl+Gap)
       %Combine syllable and the following gap 
       numInts = size(pData(i).intervals,2);
       rm = 1:2:numInts;
       idx = 1;
       for j = rm(1:end-1)
          int(:,idx) = pData(i).intervals(:,j)+pData(i).intervals(:,j+1);
          idx = idx+1;
       end
       int(:,idx) = pData(i).intervals(:,end);
       
    else %Syl and Gap
        int = pData(i).intervals;

    end
    
    %Insert into the output structure
    int_out(indx{i},:) = int;
    
    %Calc/format timepoints
    dt(indx{i}) = (pData(i).date + (pData(i).time/24));

end

function [dt, means, stds] = tempMotifFrac(pData, intType)
%Do the stats on the parsed data
numBins = length(pData);
for i = 1:numBins
    ints = [];
    if ~intType %(Syl+Gap)
       %Combine syllable and the following gap 
       numInts = size(pData(i).intervals,2);
       rm = 1:2:numInts;
       idx = 1;
       for j = rm(1:end-1)
          ints(:,idx) = pData(i).intervals(:,j)+pData(i).intervals(:,j+1);
          idx = idx+1;
       end
       ints(:,idx) = pData(i).intervals(:,end);
        
    else %Syl and Gap
        ints = pData(i).intervals;
    end
    
    %Calc motif fraction
    totals = sum(ints,2);
    motifFract = ints./totals;
    
    %sum stats
    means(i,:) = mean(motifFract,1);
    stds(i,:) = std(motifFract,1,1);

    %Calc/format timepoints
    dt(i) = mean(pData(i).date',1) + mean(pData(i).time',1)/24;    

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Data load functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function push_addDataset_Callback(hObject, eventdata, handles)
%This function adds new dataset files to the filelist, sorts them, and
%displays in the listbox. Some basic processing is done, but no data is
%loaded from the source. (That requires an additional button click.)

%Initialize variable if necessary
if ~isfield(handles, 'datasetFilename')
    handles.datasetFilename = [];
end

%Check preconditions for loading files
if ~isempty(handles.datasetFilename)
    set(handles.text_message,'String',['Hey, dickhead: Try clearing the current datasets before adding new ones.']);
    
else
    %Load the filelist
    %Get the locations of the processed files (multiselect is possible)
    [temp,path] = uigetfile('*.mat','Select the dataset file.','MultiSelect','on');
    
    if isequal(temp,0) || isequal(path,0)
        %If they hit cancel or choose something dumb, generate error and end.
        set(handles.text_message,'String','Dataset location invalid or cancelled. Pick a valid file.');
    else
        %If they don't, then parse the locations.
        fnames = [];
        if iscell(temp)
            %If there is more than one files selected, struct it
            for i = 1:size(temp,2)
                fnames{i} = char(temp{i});
                pathTot{i} = [path char(temp{i})];
            end
        else
            %Otherwise, just copy it out.
            fnames = temp;
            pathTot = [path,temp];
            i = 1;
        end
        
        %This is the code for loading the first/only folder
        handles.datasetFilename = pathTot;
        datatitles = fnames;
        
        %Sort the datatitles alphabetically (which is also chronologically if
        %only one bird) and use the index to sort the datasetFilename as well
        if iscell(datatitles)
            [handles.datatitles, ind] = sort(datatitles);
            handles.datasetFilename = handles.datasetFilename(ind);
        else
            handles.datatitles = datatitles;
            handles.datasetFilename = handles.datasetFilename;
        end
        
        %Set the message to show annotation replaced
        set(handles.listbox_datasets,'String',handles.datatitles)
        set(handles.text_message,'String',['Added ' num2str(i) ' new datasets to the active list']);
        
    end
end

guidata(hObject, handles);

function push_clearDatasets_Callback(hObject, eventdata, handles)
%Get user confirmation on clearing the list
button = questdlg('Are you sure you want to clear all datasets?','Clear datasets?','Yeah, fuck it.','Nooooo!','Nooooo!');

if (strcmp(button,'Yeah, fuck it.'))
    %Clear pointers to the datasets and their labels
     handles.datasetFilename = [];
     handles.datatitles = [];
     
    %Add here whatever other shit needs to be cleared from memory


    %Set the message to show datasets replaced
    set(handles.listbox_datasets,'String',handles.datatitles)
    set(handles.text_message,'String','All datasets cleared.');
else
    set(handles.text_message,'String','Datasets are unchanged.');
end

guidata(hObject, handles);

function push_loadDataset_Callback(hObject, eventdata, handles)
%Load the data from the saved .dat and .wav files to the workspace
if isempty(handles.datasetFilename)
    set(handles.text_message,'String','No datasets found to load, Dipshit. Check list, add files and try again.')
else
    %Figure out how many data sets we're loading here
    numDatasets = numel(handles.datasetFilename);

% %Talon output structure:
% filenames = filt_keys(handles.chosenStartSeq(:,1));
% filenums = filt_filenums(handles.chosenStartSeq(:,1));
% sequence = contents(get(handles.popup_seqSylls,'Value'),:);
% 
% %Template Data
% data.templatesyllBreaks = handles.data.templatesyllBreaks;
% data.template = handles.data.template;
% 
% %Alignment paths
% data.AlignType = get(handles.popup_alignType,'Value');
% data.p = handles.data.p;
% data.q = handles.data.q;
% data.pFull = handles.data.pFull;
% data.snipTimes = handles.data.snipTimes;
% 
% %Audio Data
% audio.raw = handles.data.audio;
%
% %Experiment Status
% data.drugsStatus = handles.data.drugsStatus;
% data.directStatus = handles.data.directStatus;
% data.flag = handles.data.flag;

    %Cycle through each dataset, load from file, and extract needed info.
    h = waitbar(0,'Loading datasets and extracting intervals. Please wait...');
    handles.dataset = [];
    for i = 1:numDatasets
        
        %Load specific variables from file
        if get(handles.check_tempOnly, 'Value')
            if iscell(handles.datasetFilename)
                load(handles.datasetFilename{i},'data','filenames','sequence')
            else
                load(handles.datasetFilename,'data','filenames','sequence')
            end
            audio.raw = [];
        else
            if iscell(handles.datasetFilename)
                load(handles.datasetFilename{i},'audio','data','filenames','sequence')
            else
                load(handles.datasetFilename,'audio','data','filenames','sequence')
            end
        end

        %Parse the filenames for the time of recordings
         [dateVect,timeVect] = extractTimeVects(filenames);
        
        %Parse the sequence data to strip out the rendition count
        sp = regexp(sequence,' ','split');
        seqCheck(i) = str2double(sp(1));

        % Generate the interval labels for the first dataset loaded... this could cause problems if datasets aren't for the
        % same sequence, but this would ikely show up somewhewre else and vcrash the whole thing...
        if i ==1;
            seq = str2double(sp(1));
            %Create Interval Labels
            sgLabels = {};
            sNgLabels = {};
            sLabels = {};
            for j = 1:length(sp{1})
                %Labels for breaking out gaps from syllables
                sgLabels = [sgLabels; sp{1}(j)];
                if j ~= length(sp{1}) 
                    sgLabels = [sgLabels; [sp{1}(j) 'G']];
                end

                %Labels for joinging syllables and gaps
                if j ~= length(sp{1})
                    sNgLabels = [sNgLabels; [sp{1}(j) '+G']];
                else
                    sNgLabels = [sNgLabels; sp{1}(j)];
                end

                %Labels for just syllables
                sLabels = [sLabels; sp{1}(j)];
            end
            %Copy out
            handles.sgLabels = sgLabels;
            handles.sNgLabels = sNgLabels;
            handles.sLabels = sLabels;
        end
        
        %Extract S/G intervals for all renditions
        IntMat = extractIntervals(data.p, data.q, data.templatesyllBreaks);
        
        %Switch for excluding flagged files
        ind = [];
        if ~get(handles.check_flags, 'Value')
            ind = true(numel(filenames), 1);
            
        else
            if isfield(data, 'flag')
                ind = ~(data.flag); % flag(i) == true means exclude motif i !!!
            else
                ind = true(numel(filenames), 1);
                set(handles.text_message, 'String', ['There is no flags array in dataset ' handles.datasetFilename{i} '. All motifs included; save as a Talon set to exclude.'])
            end
        end
        %Copy out data to the handles structure
        handles.dataset(i).renditionFilenames = filenames(ind);
        handles.dataset(i).dateVect = dateVect(ind);
        handles.dataset(i).timeVect = timeVect(ind);
        
        handles.dataset(i).templatesyllBreaks = data.templatesyllBreaks;
        handles.dataset(i).templatesyllSizes = diff(data.templatesyllBreaks,1,2)';
        handles.dataset(i).p = data.p(ind);
        handles.dataset(i).q = data.q(ind);
        
        handles.dataset(i).intervals = IntMat(ind,:);
        if ~get(handles.check_tempOnly, 'Value')
            handles.dataset(i).audio = audio.raw(ind);
        end

        %Clear out already processed data to free memory
        clear('audio','data','filenames','sequence');
        waitbar(i/numDatasets)
    end
    set(handles.text_message,'String','Dataset creation now completed.')
    close(h) 
end

%Update parse names
handles.parseNames = updateParseNames(handles);
set(handles.list_norm, 'String', handles.parseNames);

%Update Interval list
if get(handles.radio_SylsGaps, 'Value')
    set(handles.list_SylGap, 'String', handles.sgLabels, 'Value', 1)
elseif get(handles.radio_SylNGap, 'Value')
    set(handles.list_SylGap, 'String', handles.sNgLabels, 'Value', 1)
end

%Update zero day
sp = regexp(handles.datasetFilename{1}, '_', 'split');
day0 = [sp{2}(3:4), '/' sp{2}(5:6) '/' sp{2}(1:2)];
set(handles.edit_zeroDay, 'String', day0);

%Perhaps should check to make sure all of the sequences are the same
if length(unique(seqCheck)) > 1
    warndlg('Not all datasets appear to have the same syllable sequence. Likely problems ahead.');
    uiwait;
end

guidata(hObject, handles);

function check_tempOnly_Callback(hObject, eventdata, handles)

function listbox_datasets_Callback(hObject, eventdata, handles)

function listbox_datasets_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Parsing functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function edit_parseTimes_Callback(hObject, eventdata, handles)
%Update parse names
handles.parseNames = updateParseNames(handles);
set(handles.list_norm, 'String', handles.parseNames);

guidata(hObject, handles);

function edit_parseTimes_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_numMotifs_Callback(hObject, eventdata, handles)

function edit_numMotifs_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_zeroDay_Callback(hObject, eventdata, handles)

function edit_zeroDay_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function list_SylGap_Callback(hObject, eventdata, handles)

function list_SylGap_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function radio_SylsGaps_Callback(hObject, eventdata, handles)
%Checking this box, sets the paired box to false
set(handles.radio_SylNGap,'Value',0);

%You may not uncheck the box
if ~get(handles.radio_SylsGaps,'Value')
    set(handles.radio_SylsGaps,'Value',1);
end

%Update the listbox values
if isfield(handles, 'sgLabels')
    set(handles.list_SylGap, 'String', handles.sgLabels, 'Value', 1)
end

guidata(hObject, handles);

function radio_SylNGap_Callback(hObject, eventdata, handles)
%Checking this box, sets the paired box to false
set(handles.radio_SylsGaps,'Value',0);

%You may not uncheck the box
if ~get(handles.radio_SylNGap,'Value')
    set(handles.radio_SylNGap,'Value',1);
end

%Update the listbox values
if isfield(handles, 'sgLabels')
    set(handles.list_SylGap, 'String', handles.sNgLabels, 'Value', 1)
end

guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Temporal Analysis functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function popup_tempSelect_Callback(hObject, eventdata, handles)
%On new selectrion, clear the plot axis
axes(handles.axes1); cla

guidata(hObject, handles);

function popup_tempSelect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function push_tempPlot_Callback(hObject, eventdata, handles)
%Main calling function for the temporal analysis scripts

%Select the plotting axis
if get(handles.check_exportPlot, 'Value')
    figure;
else
    axes(handles.axes1);
end
cla; hold on

%Get zeroDay for plotting
zeroDay = datenum(get(handles.edit_zeroDay, 'String'), 'mm/dd/yy');

%Get interval selections from GUI controls
vals = get(handles.list_SylGap, 'Value');
contents = get(handles.list_SylGap, 'String');
numConts = numel(contents);
if get(handles.radio_SylsGaps,'Value')
    intType = 1;
else
    intType = 0;
end

%Parse data acoording to user selections
handles.pData = parseData(handles);

%Based on the popup selections, run the analysis and plotting subroutines specified
tempSelect = get(handles.popup_tempSelect, 'Value');
switch tempSelect
    %Simple mean +/- std
    case 1 
        %Run stats
        [dt, means, stds] = tempSimple(handles.pData, intType);
        
        %Normalize if requested
        if get(handles.check_norm, 'Value')
            stds = stds./means;
            means = normData(get(handles.list_norm,'Value'), means);
        end
        
        %Plot simple output
        for i = 1:length(vals)
            errorbar(floor(dt)-zeroDay, means(:,vals(i)), stds(:,vals(i)), [':' handles.symbolcell{i} handles.colorcell{i}], 'LineWidth', 1.5)
        end
        
        %Set labels
        if get(handles.check_norm, 'Value')
            ylabel('Norm Duration (%)')
        else
            ylabel('Duration (ms)')
        end
        title('Interval Durations (M+/-Std)');
        
        %Push vars to base workspace if selected
        if get(handles.check_pushVars, 'Value')
            assignin('base', 'time', floor(dt)-zeroDay)
            assignin('base', 'means', means(:,vals))
            assignin('base', 'stds', stds(:,vals))
        end
        
    %All interval durations
    case 2 
        %Run stats
        [dt, ints, indx] = tempAll(handles.pData, intType);
        
        %Normalize if requested
        if get(handles.check_norm, 'Value')
            mInd = [];
            for i = get(handles.list_norm,'Value')
                mInd = [mInd indx{i}];
            end
            ints = normData(mInd, ints);
        end

        %Plot simple output
        for i = 1:length(vals)
            scatter(dt-zeroDay, ints(:,vals(i)), ['.' handles.colorcell{i}])
        end
        
        %Set labels
        if get(handles.check_norm, 'Value')
            ylabel('Norm Duration (%)')
        else
            ylabel('Duration (ms)')
        end
        title('Interval Durations');
    
        %Push vars to base workspace if selected
        if get(handles.check_pushVars, 'Value')
            assignin('base', 'time', dt-zeroDay)
            assignin('base', 'durations', ints(:,vals))
        end
        
    %CV    
    case 3 
        %Run stats
        [dt, means, stds] = tempSimple(handles.pData, intType);
        cvs = stds./means;
        
        %Normalize if requested
        if get(handles.check_norm, 'Value')
            cvs = normData(get(handles.list_norm,'Value'), cvs);
        end
        
        %Plot simple output
        for i = 1:length(vals)
            plot(floor(dt)-zeroDay, cvs(:,vals(i)), [':' handles.symbolcell{i} handles.colorcell{i}], 'LineWidth', 1.5)
        end
        
        %Set labels
        if get(handles.check_norm, 'Value')
            ylabel('Norm CV')
        else
            ylabel('CV (%)')
        end
        title('Duration Coefficient of Variation');
        
        %Push vars to base workspace if selected
        if get(handles.check_pushVars, 'Value')
            assignin('base', 'time', floor(dt)-zeroDay)
            assignin('base', 'cvs', cvs(:,vals))
        end
        
    %Motif fraction
    case 4 
        %Run stats
        [dt, means, stds] = tempMotifFrac(handles.pData, intType);
        
        %Normalize if requested
        if get(handles.check_norm, 'Value')
            stds = stds./means;
            means = normData(get(handles.list_norm,'Value'), means);
        end
        
        %Plot simple output
        for i = 1:length(vals)
            errorbar(floor(dt)-zeroDay, means(:,vals(i)), stds(:,vals(i)), [':' handles.symbolcell{i} handles.colorcell{i}], 'LineWidth', 1.5)
        end
        
        %Set labels
        if get(handles.check_norm, 'Value')
            ylabel('Norm Motif Fraction')
        else
            ylabel('Motif Fraction (%)')
        end
        title('Motif Fraction (M+/-Std)');
        
        %Push vars to base workspace if selected
        if get(handles.check_pushVars, 'Value')
            assignin('base', 'time', floor(dt)-zeroDay)
            assignin('base', 'means', means(:,vals))
            assignin('base', 'stds', stds(:,vals))
        end
end

%Final axis formatting
handles = formatAxis(handles, contents(vals));
xlabel('Time (Days)')
hold off

guidata(hObject, handles);

function push_saveParsed_Callback(hObject, eventdata, handles)
%This function only exports minimimally processed data (essentially the
%parseData output.

%Get the intervals to plot
pData = parseData(handles);

[SaveName,SavePath] = uiputfile('*.mat');
save([SavePath SaveName],'pData');

function check_pushVars_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Variance Decomposition functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function push_varDecomp_Callback(hObject, eventdata, handles)
% Estimate parameters and latent variables for the timing variability model described in Glaze & Troyer (2012).

%Reset the storage variable if it exists
if isfield(handles, 'varComp')
    handles = rmfield(handles, 'varComp');
end

%Parse Data
handles.pData = parseData(handles);

%Do the decomposition on each of the binned sets
Q = 2; %Global dimensions; many possible but first two are most usual
numBins = numel(handles.pData);
%Cycle through each dataset, load from file, and extract needed info.
h = waitbar(0,'Running Variance Decomposition on each data bin. Please wait...');
for i = 1:numBins
    %Execute the variance decomposition model (Glaze & Troyer 2012)
    [handles.varComp.modelstrct(i),z,u,eta,W0,sigma0,psi0] = timing_var_EM(handles.pData(i).intervals,Q);

    %Calc/format timepoints
    handles.varComp.dt(i) = (handles.pData(i).date(1) + (handles.pData(i).time(1)/24));
    
    %Update waitbar
    waitbar(i/numBins)
end
close(h) 

% If the decomposition has completed, populate the selection box with the full set of intervals
set(handles.listbox_varIntSelect, 'String', handles.sgLabels);

%Plot the output given user selections
handles = plotVarComp(handles);

%Copy useful data out to save structure
% handles.saveData = [];
% handles.saveData.time = dt-zeroDay;
% handles.saveData.int_m = int_m;
% handles.saveData.int_std = int_std;
% 
% handles.saveData.dataType = contents(vals);
% handles.saveData.parseTime = str2num(get(handles.edit_parseTimes,'String'));
% handles.saveData.parseNum = str2num(get(handles.edit_numMotifs,'String'));
% handles.saveData.normed = get(handles.check_norm, 'Value');
% handles.saveData.normRef = get(handles.list_norm,'Value');
% handles.saveData.fileSets = get(handles.list_norm,'String');

guidata(hObject, handles);

function popup_varPSelect_Callback(hObject, eventdata, handles)
%Check to verify that the decomp model has previously been run
if ~isfield(handles, 'varComp')
    set(handles.text_message, 'String', 'You need to run the Decompposition before you can plot parameters')
else
    handles = plotVarComp(handles);
end

guidata(hObject, handles);

function popup_varPSelect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function check_showVarInts_Callback(hObject, eventdata, handles)
%Check to verify that the decomp model has previously been run
if ~isfield(handles, 'varComp')
    set(handles.text_message, 'String', 'You need to run the Decomposition before you can plot parameters')
else
    handles = plotVarComp(handles);
end

guidata(hObject, handles);

function check_mGaps_Callback(hObject, eventdata, handles)
%Check to verify that the decomp model has previously been run
if ~isfield(handles, 'varComp')
    set(handles.text_message, 'String', 'You need to run the Decomposition before you can plot parameters')
else
    handles = plotVarComp(handles);
end

guidata(hObject, handles);

function check_mVarSyls_Callback(hObject, eventdata, handles)
%Check to verify that the decomp model has previously been run
if ~isfield(handles, 'varComp')
    set(handles.text_message, 'String', 'You need to run the Decomposition before you can plot parameters')
else
    handles = plotVarComp(handles);
end

guidata(hObject, handles);

function listbox_varIntSelect_Callback(hObject, eventdata, handles)

function listbox_varIntSelect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Spectral Analysis functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function push_syllSim_Callback(hObject, eventdata, handles)
% Run the SAP-style similarity analysis on the 

%Reset the storage variable if it exists
if isfield(handles, 'simAnalysis')
    handles = rmfield(handles, 'simAnalysis');
end

%Parse Data
handles.pData = parseData(handles);

%Do the similarity analysis on each of the binned sets
numBins = numel(handles.pData);

%Temp Set the filtering/gain factors
handles.prep.gain = [10, 10, 10, 10, 10, 10, 10, 10, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
handles.prep.hp = [800, 800, 800, 800, 800, 800, 800, 800, 800, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300];
handles.prep.lp = [8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500]; 

%Cycle through each binned dataset, load from file, and extract needed info.
h = waitbar(0,'Running Similarity Analysis on each data bin. Please wait...');
for i = 1:numBins
    %Extract syllables from the motifs
    sylSnips = extractSyllables(handles, handles.pData(i), i);
    
    %Calc the duration of the template syllables
    durs = diff(handles.pData(i).templatesyllBreaks,1,2)';
    
    %Cycle through each syllable in a bin to and process separately
    numSyls = size(sylSnips,2);
    for j = 1:numSyls
        %Snips for a single syllable
        subSet = sylSnips(:,j);
    
%         %Prep audio
%         subSet = Prep(handles,subSet);
        
        %Run similarity analysis on the syllable subset
        [handles.simAnalysis(i).accScores(:, j), handles.simAnalysis(i).simScores(:, j), ~] = batchSapSimilarity(subSet, durs(j));       
        
    end

    %Calc/format timepoints
    handles.simAnalysis(i).dt = (handles.pData(i).date(1) + (handles.pData(i).time(1)/24));
    
    %Update waitbar
    waitbar(i/numBins)
end
close(h) 

% If the decomposition has completed, populate the selection box with the full set of intervals
set(handles.listbox_simIntSelect, 'String', handles.sLabels);

%Plot the output given user selections
% handles = plotSimAnalysis(handles);

%Copy useful data out to save structure
% handles.saveData = [];
% handles.saveData.time = dt-zeroDay;
% handles.saveData.int_m = int_m;
% handles.saveData.int_std = int_std;
% 
% handles.saveData.dataType = contents(vals);
% handles.saveData.parseTime = str2num(get(handles.edit_parseTimes,'String'));
% handles.saveData.parseNum = str2num(get(handles.edit_numMotifs,'String'));
% handles.saveData.normed = get(handles.check_norm, 'Value');
% handles.saveData.normRef = get(handles.list_norm,'Value');
% handles.saveData.fileSets = get(handles.list_norm,'String');

guidata(hObject, handles);


function push_recovery_Callback(hObject, eventdata, handles)
% Run the SAP-style syllable recovery analysis

%Reset the storage variable if it exists
if isfield(handles, 'simAnalysis')
    handles = rmfield(handles, 'simAnalysis');
end

%Parse Data
handles.pData = parseData(handles);

%Do the similarity analysis on each of the binned sets
numBins = numel(handles.pData);

%Temp Set the filtering/gain factors
handles.prep.gain = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
handles.prep.hp = [300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300];
handles.prep.lp = [8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500, 8500]; 

%Retrieve the reference/baseline data from the "Interval Selection" listbox
pntr = get(handles.list_norm,'Value');
if numel(pntr)~=1
    set(text.message,'String', 'You must select one (and only one) reference day for the recovery analysis.')
    return
end

REFsylSnips = extractSyllables(handles, handles.pData(pntr), pntr);
% REFdurs = diff(handles.pData(pntr).templatesyllBreaks,1,2)';

%Cycle through each binned dataset, load from file, and extract needed info.
h = waitbar(0,'Running Recovery Analysis on each data bin. Please wait...');
for i = 1:numBins
    %Extract syllables from the motifs
    sylSnips = extractSyllables(handles, handles.pData(i), i);
    
    %Calc the duration of the template syllables
    durs = diff(handles.pData(i).templatesyllBreaks,1,2)';
    
    %Cycle through each syllable in a bin to and process separately
    numSyls = size(sylSnips,2);
    for j = 1:numSyls
        %Snips for a single syllable
        REFsubSet = REFsylSnips(:,j);
        subSet = sylSnips(:,j);
    
%         %Prep audio
%         subSet = Prep(handles,subSet);
        
        %Run similarity analysis on the syllable subset
        [handles.simAnalysis(i).accScores(:, j), handles.simAnalysis(i).simScores(:, j), ~] = batchSapRecovery(subSet, durs(j), REFsubSet);       
        
    end

    %Calc/format timepoints
    handles.simAnalysis(i).dt = (handles.pData(i).date(1) + (handles.pData(i).time(1)/24));
    
    %Update waitbar
    waitbar(i/numBins)
end
close(h) 

% If the decomposition has completed, populate the selection box with the full set of intervals
set(handles.listbox_simIntSelect, 'String', handles.sLabels);

%Plot the output given user selections
% handles = plotSimAnalysis(handles);

%Copy useful data out to save structure
% handles.saveData = [];
% handles.saveData.time = dt-zeroDay;
% handles.saveData.int_m = int_m;
% handles.saveData.int_std = int_std;
% 
% handles.saveData.dataType = contents(vals);
% handles.saveData.parseTime = str2num(get(handles.edit_parseTimes,'String'));
% handles.saveData.parseNum = str2num(get(handles.edit_numMotifs,'String'));
% handles.saveData.normed = get(handles.check_norm, 'Value');
% handles.saveData.normRef = get(handles.list_norm,'Value');
% handles.saveData.fileSets = get(handles.list_norm,'String');

guidata(hObject, handles);


function check_mSimSyls_Callback(hObject, eventdata, handles)
%Check to verify that the decomp model has previously been run
if ~isfield(handles, 'simAnalysis')
    set(handles.text_message, 'String', 'You need to run the Similarity Analysis before you can plot parameters')
else
    handles = plotSimAnalysis(handles);
end

guidata(hObject, handles);

function check_showSimInts_Callback(hObject, eventdata, handles)
%Check to verify that the decomp model has previously been run
if ~isfield(handles, 'simAnalysis')
    set(handles.text_message, 'String', 'You need to run the Similarity Analysis before you can plot parameters')
else
    handles = plotSimAnalysis(handles);
end

guidata(hObject, handles);

function listbox_simIntSelect_Callback(hObject, eventdata, handles)

function listbox_simIntSelect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function check_flags_Callback(hObject, eventdata, handles)

function check_rms_Callback(hObject, eventdata, handles)


function push_syls2Disk_Callback(hObject, eventdata, handles)
% Cut up syllables into snips and write to disk for analysis elsewhere

%Request the location for saving files
parent = uigetdir(cd, 'Where to save these syllables?');

%Parse Data
handles.pData = parseData(handles);

%Cycle through each binned dataset, load from file, and extract needed info.
numBins = numel(handles.pData);
h = waitbar(0,'Running Similarity Analysis on each data bin. Please wait...');
for i = 1:numBins
    %Extract syllables from the motifs
    sylSnips = extractSyllables(handles.pData(i));
    fold1 = ['Day' num2str(i)];
    
    %Cycle through each syllable in a bin to and write wave separately
    numSyls = size(sylSnips,2);
    for j = 1:numSyls
        fold2 = ['Syl' num2str(j)];
        
        if ~exist([parent filesep fold1 filesep fold2 filesep])
            mkdir([parent filesep fold1 filesep fold2 filesep])
        end
        
        %Snips for a single syllable
        subSet = sylSnips(:,j);
    
        %Write each to disk
        for k = 1:numel(subSet)
            fname = [parent filesep fold1 filesep fold2 filesep num2str(k) '.wav'];
            audiowrite(fname, subSet{k}, 44150);
        end
    end
    
    %Update waitbar
    waitbar(i/numBins)
end
close(h) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Save/export functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function push_saveRaw_Callback(hObject, eventdata, handles)
%Capture all of the raw data that's been imported from file. No processing included.
datasets = handles.dataset;

%Get location to save
[SaveName,SavePath] = uiputfile('*.mat');

%Save it
save([SavePath SaveName],'datasets');

%Notify user when done
set(handles.text_message, 'String', ['Raw data saved to file at: ' SaveName]);

function push_saveFinal_Callback(hObject, eventdata, handles)
dataOut = handles.saveData;

[SaveName,SavePath] = uiputfile('*.mat');
save([SavePath SaveName],'dataOut');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Misc functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function check_exportPlot_Callback(hObject, eventdata, handles)

function push_help_Callback(hObject, eventdata, handles)
%Format the help message
help_string=['Keyboard Shortcuts:' ...
    sprintf('\n') 'comma(,) - zoom back' ...
    sprintf('\n') 'period(.) - zoom forward' ...
    sprintf('\n') 'delete - delete syllable' ...
    sprintf('\n') 'm - delete pause'...
    sprintf('\n') 'p - play sound' ...
    sprintf('\n') 'space bar - jump to next syllable' ...
    sprintf('\n') ...
    sprintf('\n') 'Labeling Syllables:' ...
    sprintf('\n') '1-10 - labels syllables 1-10' ...
    sprintf('\n') 'u - unknown syllable' ...
    sprintf('\n') 'c - call' ...
    sprintf('\n') 'n - CAF noise+syllable' ...
    sprintf('\n') 's - subsong' ...
    sprintf('\n') ...
    sprintf('\n') 'Segmenting Plot Guides:' ...
    sprintf('\n') 'Red Vertical Lines - Syllable Edges'...
    sprintf('\n') 'Solid Black Line - Bout Detection Threshold'...
    sprintf('\n') 'Bold Colored Boxes - Detected Bouts'...
    sprintf('\n') 'Dashed Colored Lines - Syllable Edge Threshold' ...
    sprintf('\n') 'Dotted Colored Lines - Syllable Continuation Threshold'...
    sprintf('\n') ...
    sprintf('\n') 'Filelist Color Codes:' ...
    sprintf('\n') 'Plain text - Unannotated File'...
    sprintf('\n') 'Bold text w/ Green Highlight - Annotated File'...
    sprintf('\n') 'Blue text w/ Green Highlight - Annotated File w/ Segmenting Error'...
    sprintf('\n') 'Red text - File Errored During Batch Process'];

%Display in a dialog box
helpdlg(help_string,'Legend for plots and keyboard shortcuts');

guidata(hObject, handles);

function list_norm_Callback(hObject, eventdata, handles)

function list_norm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function check_norm_Callback(hObject, eventdata, handles)

function push_test1_Callback(hObject, eventdata, handles)
