function counts = countsVector(countBlock) %convert a block of counts into a vector

   [string,~] = stringArrayCat('',countBlock);
   string(string>char('9') | string<char('0')) = ' ';
   counts = str2num(string)';

end