function Rout = rois_in_bb(R,bb) % bb [x1 y1 w h]
sz = [1024 1024];

mat = zeros(sz);
mat(bb(2):(bb(2)+bb(4)), bb(1):(bb(1)+bb(3))) = 1;

inds = find(mat);

Rout = [];

for r=1:numel(R)
   if ~isempty(intersect(inds,R(r).pixel_idx))
      Rout = cat(1,Rout,R(r)); 
   end
end

end