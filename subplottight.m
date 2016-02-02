function h = subplottight(n,m,i)
%http://www.briandalessandro.com/blog/how-to-make-a-borderless-subplot-of-images-in-matlab/
    [c,r] = ind2sub([m n], i);
    ax = subplot('Position', [(c-1)/m, 1-(r)/n, 1/m, 1/n]);
    if(nargout > 0)
      h = ax;
    end