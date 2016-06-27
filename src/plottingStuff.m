%plotting stuff
p1 = plot([resultStruct.AvgAccuracy]);
set(p1,'linewidth',2);
ax=gca;

axis([0 11 0 1])
ax.XTick = [0:20];
ax.YTick = [0:0.1:1];
title('Test results of skew deviation limit test')
xlabel('Tested value')
ylabel('Detection accuracy')

p2 = plot([resultStruct.AvgPreProcessingTime]);
set(p2,'linewidth',2)
ax.XTick = [1:21];
title('Pre-processing time of n1 parameter test')
xlabel('Tested value')
ylabel('Pre-processing time in seconds')


p3 = plot([resultStruct.AvgLineDetectionTime]);
ax.XTick = [0:20];
title('Line detection time of average distance margin test')
xlabel('Tested value')
ylabel('Pre-processing time in seconds')
ylabel('Line detection time in seconds')
set(p3,'linewidth',2)ax.YTick = [0:0.1:1];