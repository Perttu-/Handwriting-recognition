function  houghTransform(image,thetas,rhoResolution)
    image = flipud(image);
    [imgWidth,imgHeight] = size(image);
    
    [xIndices,yIndices] = find(image);
    rhoLimit = sqrt(imgHeight^2+imgWidth^2);
    rhos = -rhoLimit:rhoResolution:rhoLimit;
    accumulatorArray = zeros(numel(rhos),numel(thetas));
    
    imshow(image);
    hold on;
    x(1)=0;
    y(1)=0;
    x = zeros(numel(thetas)*numel(rhos),2);
    y = zeros(numel(thetas)*numel(rhos),2);
    xp = x;
    yp = y;

    for t = thetas
        for r = rhos
            x(2)=x(1)+r*cosd(t);
            y(2)=y(1)+r*sind(t);
            %plot(x(2),y(2),'r*');
            %line(x,y);
            t2 = t+90;
            

        end
    end

    rh = xIndices*cos(thetas)+yIndices*sin(thetas);

end