function visualizeCentroids (image,centroids,pointType)
    imshow(image);
    hold on;
    plot(centroids(:,1),centroids(:,2), pointType)
    hold off;
end