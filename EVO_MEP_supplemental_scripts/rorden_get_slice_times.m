% Modified from Chris Rorden's script for calculating slice times for Philips scanners
% Holland Brown
% Updated: 2023-09-01
% Source: https://neurostars.org/t/deriving-slice-timing-order-from-philips-par-rec-and-console-information/17688/2

TRsec = 1.399999;
nSlices = 144;
TA = TRsec/nSlices; %assumes no temporal gap between volumes
bidsSliceTiming=[0:TA:TRsec-TA]; %ascending

if false %descending
    bidsSliceTiming = flip(bidsSliceTiming);
end

if true %interleaved
    order = [1:2:nSlices 2:2:nSlices]
    bidsSliceTiming(order) = bidsSliceTiming;
end

%report results
fprintf(' "SliceTiming": [\n');
for i = 1 : nSlices
    fprintf(' %g', bidsSliceTiming(i));
    if (i < nSlices)
        fprintf(',\n');
    else
        fprintf(' ],\n');
    end
end