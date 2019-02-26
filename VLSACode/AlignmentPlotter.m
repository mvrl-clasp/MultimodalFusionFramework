clear;clc;
% we plot the words corresponding to the image regions as obtained from the
% alignment framework i.e. Berkeley aligner
clustcentPath = '~/desktop/vlsa/vlsadata/clusters/MSFC/';
dataImagePath = '~/desktop/vlsa/vlsadata/images/';
alignConfPath = '~/desktop/vlsa/vlsaunits/MSFC_NPJJ/';
ImageList = [1];
% Select the wordcase: all - all aligned words 
%                     topk - top k words (based on frequency) 
WordCase = 'topk'; 
K = 3; % select top k words to be plotted 
% Select the labelcase: all = all labels aligned to a word
%                        topl - top l labels that a word is aligned with
LabelCase = 'topl';
L = 1; % select top l labels to be plotted
%%
for img = 1:size(ImageList,2)
    im = ImageList(img);
    % load current image's MSFC cluster centers
    clustcent = load([clustcentPath, int2str(im),'_clustcent.mat']);
    clustcent = clustcent.clustCent;
    % read image
    Image = imread([dataImagePath,int2str(im),'.jpg']);
    % read the output from the aligner. Berkeley or baseline
    fileID = fopen([alignConfPath,int2str(im),'/output/AlignConf.csv']);
    alignment = textscan(fileID, '%s');
    alignment = alignment{:};

    
    %% get the aligned word (lu), label (vu), and the particular alignnment's freq separated
    Words = [];
    Label = [];
    Freq = [];
    clustX = [];
    clustY = [];
    for l = 1:length(alignment)
        alignlist = strsplit(alignment{l},',');
        Word{l} =  alignlist{1};
        Label{l} =  str2double(alignlist{2});
        Freq{l} =  str2double(alignlist{3});
        clustX{l} = clustcent(1,Label{l});
        clustY{l} = clustcent(2,Label{l});
    end
    % get a uniqued list of the words so we can control how many words we
    % show. This is a list of uniqued words that were aligned and they are in the order of
    % their frequency in the lu files. 
    % to preserver order use 'stable'
    UniqWord = unique(Word, 'stable'); 
    
    
   %% select words based on plotting Case (all or topk)
    selectwords =[];
    selectlabel = [];
    if strcmp(WordCase,'all')        
        if strcmp(LabelCase,'all')            
            selectlabel = Label;
            selectwords = Word;
        elseif strcmp(LabelCase,'topl')
            for z = 1:length(UniqWord)
                idx = find(strcmp(Word,UniqWord{z}));
                idx = idx(1:min(L, length(idx)));
                selectlabel = [selectlabel Label(idx)];
                selectwords = [selectwords Word(idx)];
            end
        end
    elseif strcmp(WordCase,'topk')       
            % select top k words and their top k locations only
            TopkWords = cell(K,1);
            for z = 1:K
                TopkWords{z} = UniqWord{z};
            end
            if strcmp(LabelCase,'all')
                % get the index of each topkword and its corresponding locations
                for z = 1:K
                    idx = find(strcmp(Word, TopkWords{z}));
                    % make a list of the topk words and their labels
                    selectwords = [selectwords Word(idx)];
                    selectlabel = [selectlabel Label(idx)];
                end
            elseif strcmp(LabelCase,'topl')
                for z = 1:K
                    idx = find(strcmp(Word, TopkWords{z}));
                    % select only the topk indexes for a word
                    idx = idx(1:min(L, length(idx)));
                    % make a list of the topk words and their labels
                    selectwords = [selectwords Word(idx)];
                    selectlabel = [selectlabel Label(idx)];
                end
            end
    end
    
    %% for the ground truth words and labels get the cluscents to plot on
    p = 1;
    position=[];
    for i = 1:size(selectlabel,2)
        position(p,1) = clustcent(1,(selectlabel{i}));
        position(p,2) = clustcent(2,(selectlabel{i}));
        p = p+1;
    end
    
    %%
    % now we need to make sure that duplicate positions do not occur else
    % different words belonging to the same cluster center will overlap during
    % the visualization - we need to remove duplicate locations and make a list
    % of the words belonging to the same location. more comments to come later
    %[~,pidx] = unique(strcat(position(:,1)));
    [~,pidx] = unique(position,'rows');
    textscript = cell(size(position,1),size(position,1));
    displayposition = [];
    displayword = [];
    %%
    for p = 1:size(position,1)
        if ismember(p,pidx) == 1
           textscript{p} = selectwords{p};
           displayposition(p,:) = position(p,:);
        elseif ismember(p,pidx) == 0
           for t = 1:size(position,1)              
                if position(p,1) == position(t,1) && position(p,2) == position(t,2)                    
                     textscript{t} = [textscript{t},char(10) ,selectwords{p}];%for list format
                   break;
                end
            end
        end
    end
    
    
    
    %%
    displayword = textscript(~cellfun('isempty',textscript));
    displayposition( all(~displayposition,2), : ) = [];
    

    %% plot on the original image the terms at the location specified by the cluster center
    rgb=[];
    % color definitions
    color  = {'magenta'};
    gcolor = {'yellow'};
    bcolor = {'green'};
    markercolor = {'green'};
    displaycolor    = cell(size(displayword{1},1),1);
    displaycolor(:) = color;
    gdisplaycolor(:)= gcolor;
    bdisplaycolor(:)= bcolor;
    mcolor          = cell(size(displayword{1},1),1);
    mcolor(:)       = markercolor;
    
    % actual plot on the image
    rgb = insertText(Image,displayposition,displayword,'BoxColor',displaycolor, 'FontSize',20,'TextColor','white','BoxOpacity',0.4,'AnchorPoint','LeftBottom');
    rgb = insertMarker(rgb,displayposition,'*','color',mcolor,'size',10);
    rgb = insertMarker(rgb,displayposition,'o','color',mcolor,'size',10);
    figure,imshow(rgb)
    % saveas(gcf,[OutputImageSavePath, int2str(im),'_aligned.jpg']);
%%    
end
