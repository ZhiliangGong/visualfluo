function u = gauss2linback( a, v )
%2 Gaussians with linear background
%   Zhiliang Gong, March 3, 2015

u = a(1).*exp(-((v-a(2))./a(3)).^2/2) + a(4).*exp(-((v-a(5))./a(6)).^2/2) + a(7)*v + a(8);

end