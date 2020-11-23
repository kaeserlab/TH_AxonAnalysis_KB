function [fplist,fnlist,fblist] = listfilesexcluding(folderpath, token, excepttoken)
% returns cell arrays with the filepaths/filenames of files ending with 'fileextension' in folder 'folderpath'
% token examples: '.tif', '.png', '.txt'
% fplist: list of full paths
% fnlist: list of file names
% fblist: list of file sizes in bytes

listing = dir(folderpath);
index = 0;
fplist = {};
fnlist = {};
fblist = [];
for i = 1:size(listing,1)
    s = listing(i).name;
    if ~isempty(strfind(s,token)) && isempty(strfind(s,excepttoken))
        index = index+1;
        fplist{index} = [folderpath filesep s];
        fnlist{index} = s;
        fblist = [fblist; listing(i).bytes];
    end
end