%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
classdef LustMathLib
    %LustMathLib This class  is a set of Lustre math libraries.
    
    properties
    end
    
    methods(Static)
        %% Min Max
        [node, external_nodes_i, opens, abstractedNodes] = get__min_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__min_real(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__max_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__max_real(varargin)
        %% external libraries
        [node, external_nodes_i, opens, abstractedNodes] = get_lustrec_math(lus_backend)
        [node, external_nodes_i, opens, abstractedNodes] = get_simulink_math_fcn(lus_backend)
        %% fabs, abs
        [node, external_nodes_i, opens, abstractedNodes] = get__fabs(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_abs_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_abs_real(varargin)
        %% sign
        [node, external_nodes_i, opens, abstractedNodes] = get_sign_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_sign_real(varargin)
        %% Bitwise operators
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Signed(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_32(varargin)
        %% Integer division
        % The following functions assume "/" and "mod" in Lustre as in
        % euclidean division for integers.
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Ceiling(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Floor(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Nearest(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Zero(varargin)
        %% fmod, rem, mod
        [node, external_nodes_i, opens, abstractedNodes] = get_fmod(lus_backend)
        [node, external_nodes_i, opens, abstractedNodes] = get_rem_int_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_mod_int_int(varargin)
        %% Matrix inversion
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_2x2(lus_backend, varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_3x3(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_4x4(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_5x5(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_6x6(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_7x7(lus_backend,varargin)
    end
    
end

