function copyContentsToSubsystem(bd, subsys)
% copyContentsToSubsystem copies contents of a block diagram to a subsystem
%
% Simulink.BlockDiagram.copyContentsToSubsystem copies contents of a block 
% diagram to a subsystem. The block diagram and subsystem must have already 
% been loaded.
%
% Usage: Simulink.BlockDiagram.copyContentsToSubsystem(bd, subsys)
% Inputs:
%    bd: a block diagram name or handle
%    subsys: a subsystem name or handle
%
%  Note: The Subsystem block cannot be part of the input block diagram

%   Copyright 1994-2006 The MathWorks, Inc.

  if nargin ~= 2
      DAStudio.error('Simulink:modelReference:slBDCopyContentsToSSInvalidNumInputs');
  end

  % Check the first input argument. Bd must have already be loaded.
  try
      isBd = strcmpi(get_param(bd,'type'), 'block_diagram');
  catch
      isBd = false;
  end
  
  if ~isBd
      DAStudio.error('Simulink:modelReference:slBDCopyContentsToSSIn1Invalid');
  end
  
  % Check the second input argument
  try
      isSubsys = strcmpi(get_param(subsys,'type'), 'block') && ...
          strcmpi(get_param(subsys,'blocktype'), 'Subsystem');
  catch
      isSubsys = false;
  end
  
  if ~isSubsys
      DAStudio.error('Simulink:modelReference:slBDCopyContentsToSSIn2Invalid');
  end

  % Make sure the model containing subsys is not being compiled
  ssBd = bdroot(subsys); 
  ssBdName= get_param(ssBd, 'name');
  ssBdSimStatus = get_param(ssBd,'SimulationStatus');
  if ~strcmpi(ssBdSimStatus, 'stopped')
      DAStudio.error('Simulink:modelReference:slBadSimStatus', ssBdName, ssBdSimStatus);
  end
  
  % Get the Subsystem root, and make sure the Subsystem is not inside input bd
  bdName = get_param(bd, 'name');
  if strcmpi(ssBdName, bdName)
      DAStudio.error('Simulink:modelReference:slBDCopyContentsToSSInvalidInputs');
  end

  % Now copy contents.  Undocumented APIs. Do not use them directly
  bdObj = get_param(bd,'object');
  ssH = get_param(subsys, 'handle');
  bdObj.copyContentsToSS(ssH);
  
%endfunction

  
