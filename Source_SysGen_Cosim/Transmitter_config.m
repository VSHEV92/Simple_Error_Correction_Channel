
function transmitter_config(this_block)

  % Revision History:
  %
  %   27-Aug-2020  (13:08 hours):
  %     Original code was machine generated by Xilinx's System Generator after parsing
  %     D:\DEP3\CODEC_P\Source_Verilog\Transmitter.v
  %
  %

  this_block.setTopLevelLanguage('Verilog');

  this_block.setEntityName('transmitter');

  % System Generator has to assume that your entity  has a combinational feed through; 
  %   if it  doesn't, then comment out the following line:
  this_block.tagAsCombinational;

  this_block.addSimulinkInport('reset');
  this_block.addSimulinkInport('bch_coder_on');
  this_block.addSimulinkInport('interleaver_on');
  this_block.addSimulinkInport('frame_former_on');
  this_block.addSimulinkInport('data_in');
  this_block.addSimulinkInport('data_in_we');

  this_block.addSimulinkOutport('data_in_full');
  this_block.addSimulinkOutport('data_out');
  this_block.addSimulinkOutport('data_out_valid');

  data_in_full_port = this_block.port('data_in_full');
  data_in_full_port.setType('UFix_1_0');
  data_in_full_port.useHDLVector(false);
  data_out_port = this_block.port('data_out');
  data_out_port.setType('UFix_1_0');
  data_out_port.useHDLVector(false);
  data_out_valid_port = this_block.port('data_out_valid');
  data_out_valid_port.setType('UFix_1_0');
  data_out_valid_port.useHDLVector(false);

  % -----------------------------
  if (this_block.inputTypesKnown)
    % do input type checking, dynamic output type and generic setup in this code block.

    if (this_block.port('reset').width ~= 1);
      this_block.setError('Input data type for port "reset" must have width=1.');
    end

    this_block.port('reset').useHDLVector(false);

    if (this_block.port('bch_coder_on').width ~= 1);
      this_block.setError('Input data type for port "bch_coder_on" must have width=1.');
    end

    this_block.port('bch_coder_on').useHDLVector(false);

    if (this_block.port('interleaver_on').width ~= 1);
      this_block.setError('Input data type for port "interleaver_on" must have width=1.');
    end

    this_block.port('interleaver_on').useHDLVector(false);

    if (this_block.port('frame_former_on').width ~= 1);
      this_block.setError('Input data type for port "frame_former_on" must have width=1.');
    end

    this_block.port('frame_former_on').useHDLVector(false);

    if (this_block.port('data_in').width ~= 1);
      this_block.setError('Input data type for port "data_in" must have width=1.');
    end

    this_block.port('data_in').useHDLVector(false);

    if (this_block.port('data_in_we').width ~= 1);
      this_block.setError('Input data type for port "data_in_we" must have width=1.');
    end

    this_block.port('data_in_we').useHDLVector(false);

  end  % if(inputTypesKnown)
  % -----------------------------

  % -----------------------------
   if (this_block.inputRatesKnown)
     setup_as_single_rate(this_block,'clk','ce')
   end  % if(inputRatesKnown)
  % -----------------------------

    uniqueInputRates = unique(this_block.getInputRates);


  % Add addtional source files as needed.
  %  |-------------
  %  | Add files in the order in which they should be compiled.
  %  | If two files "a.vhd" and "b.vhd" contain the entities
  %  | entity_a and entity_b, and entity_a contains a
  %  | component of type entity_b, the correct sequence of
  %  | addFile() calls would be:
  %  |    this_block.addFile('b.vhd');
  %  |    this_block.addFile('a.vhd');
  %  |-------------

  this_block.addFile('../Source_Verilog/Channel_Params.vh');
  this_block.addFile('../Source_Verilog/BCH_Codeing/BCH_Encoder.v');
  this_block.addFile('../Source_Verilog/Interleaving/Interleaver_Write_Buffer.v');
  this_block.addFile('../Source_Verilog/Interleaving/Interleaver_Read_Buffer.v');
  this_block.addFile('../Source_Verilog/Interleaving/Interleaver.v');
  this_block.addFile('../Source_Verilog/Frame_Sync/Frame_Former.v');
  this_block.addFile('../Source_Verilog/Transmitter.v');

return;


% ------------------------------------------------------------

function setup_as_single_rate(block,clkname,cename) 
  inputRates = block.inputRates; 
  uniqueInputRates = unique(inputRates); 
  if (length(uniqueInputRates)==1 & uniqueInputRates(1)==Inf) 
    block.addError('The inputs to this block cannot all be constant.'); 
    return; 
  end 
  if (uniqueInputRates(end) == Inf) 
     hasConstantInput = true; 
     uniqueInputRates = uniqueInputRates(1:end-1); 
  end 
  if (length(uniqueInputRates) ~= 1) 
    block.addError('The inputs to this block must run at a single rate.'); 
    return; 
  end 
  theInputRate = uniqueInputRates(1); 
  for i = 1:block.numSimulinkOutports 
     block.outport(i).setRate(theInputRate); 
  end 
  block.addClkCEPair(clkname,cename,theInputRate); 
  return; 

% ------------------------------------------------------------

