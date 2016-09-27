function lambda = calculateWavelength(E) %calculate the wavelength from keV
    h = 6.62606957e-34; %Planck constatn
    c = 299792458; %speed of light
    ev2j = 1.60217657e-19; %eV to Joul conversion factor
    lambda = h*c/(E*1000*ev2j)*1e10; %wavelength in A  
end