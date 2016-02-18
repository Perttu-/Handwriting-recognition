function rlsaImage = rlsa(image,rlsaThreshold)
    %run length smoothing algorithm
    [m, ~] = size(image);
    xx = [ones(m,1) image ones(m,1)];
    xx = reshape(xx',1,[]);
    d = diff(xx);
    start = find(d==-1);
    stop = find(d==1);
    lgt = stop-start;
    b = lgt <= rlsaThreshold;
    d(start(b)) = 0;
    d(stop(b)) = 0;
    yy = cumsum([1 d]);
    yy = reshape(yy, [], m)';
    rlsaImage = logical(yy(:,2:end-1));

end