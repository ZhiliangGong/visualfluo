function u = lorentzlinback(a,v) %one Lorentzian with linear background
            
    u = a(1)*a(3)^2./((v-a(2)).^2+a(3)^2) + a(4)*v + a(5);
            
end