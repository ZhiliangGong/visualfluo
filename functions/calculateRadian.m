function angle = calculateRadian(q,E) %caulculate the angle in radian
    h = 6.62606957e-34; %Planck constatn
    c = 299792458; %speed of light
    ev2j = 1.60217657e-19; %eV to Joul conversion factor
    angle = asin(q*1e10*h*c/(E*1000*ev2j)/(4*pi)); %convert q to radian
end