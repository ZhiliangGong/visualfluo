function u = lorentz2linback(a,v) %two Lorentzians with linear background
            
    u = a(1)*a(3)^2./((v-a(2)).^2+a(3)^2) + a(4)*a(6)^2./((v-a(5)).^2+a(6)^2) + a(7)*v + a(8);

end