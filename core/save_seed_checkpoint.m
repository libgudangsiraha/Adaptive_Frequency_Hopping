function save_seed_checkpoint(filePath, record, signature)
%SAVE_SEED_CHECKPOINT Atomic per-seed checkpoint write.

    folder = fileparts(filePath);
    if ~isfolder(folder)
        mkdir(folder);
    end

    temporaryFile = [tempname(folder), '.mat'];
    save(temporaryFile, 'record', 'signature', '-v7.3');
    movefile(temporaryFile, filePath, 'f');

end
