`include "amba_ahb_h.v"
`include"riscv_defines.v"
module riscv_multiplier_if #(
	parameter W_ADDR = 32,
	parameter W_DATA = 32,
	parameter WB_DATA = 4,
	parameter W_WB_DATA = 2,
	parameter W_CNT = 16,	
	parameter DEF_HPROT = {`PROT_NOTCACHE, `PROT_UNBUF, `PROT_USER, `PROT_DATA},
	parameter W_PIX = 8)
(
	//CLOCK
	HCLK,
	HRESETn,
	//input signals of control port(slave)
	sl_HREADY,
	sl_HSEL,
	sl_HTRANS,
	sl_HBURST,
	sl_HSIZE,
	sl_HADDR,
	sl_HWRITE,
	sl_HWDATA,
	//output signals of control port(slave)
	out_sl_HREADY,				
	out_sl_HRESP,
	out_sl_HRDATA
);
//CLOCK
input HCLK;
input HRESETn;
//input signals of control port(slave)
input sl_HREADY;
input sl_HSEL;
input [`W_TRANS-1:0] sl_HTRANS;
input [`W_BURST-1:0] sl_HBURST;
input [`W_SIZE-1:0] sl_HSIZE;
input [W_ADDR-1:0] sl_HADDR;
input sl_HWRITE;
input [W_DATA-1:0] sl_HWDATA;
//output signals of control port(slave)
output out_sl_HREADY;				
output [`W_RESP-1:0] out_sl_HRESP;
output reg [W_DATA-1:0] out_sl_HRDATA;

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
// Define the register map
/*Insert your code*/
localparam N_REGS = 8;	// Number of registers
localparam W_REGS = 3;	//log2(N_REGS)

localparam REG_MUL_OP_I	 	= 0;	//0x00
localparam REG_MUL_A_SIGNED	= 1;	//0x04
localparam REG_MUL_B_SIGNED	= 2;	//0x08
localparam REG_MUL_A_I	 	= 3;	//0x0c	
localparam REG_MUL_B_I	 	= 4;	//0x08
localparam REG_MUL_P_O_LO 	= 5;	//0x0c	<READ-ONLY>	
localparam REG_MUL_P_O_HI	= 6;	//0x08	<READ-ONLY>
localparam REG_MUL_EX_STALL	= 7;	//0x08	<READ-ONLY>

reg [W_REGS-1:0] q_sel_sl_reg;
reg q_ld_sl_reg;

reg [3:0] alu_op_i;
reg [31:0] alu_a_i, alu_b_i;
wire [63:0] alu_p_o;
wire ex_stall_mul_w;
reg a_signed, b_signed;
//wire [31:0] alu_p_o;
//wire [4:0] flcnz;
//wire [4:0] FLAG_alu_p_o;
//----------------------------------------------------------
// Decode Stage: Address Phase
//----------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin
	if(~HRESETn)
	begin
		//control
		q_sel_sl_reg <= 0;
		q_ld_sl_reg <= 1'b0;
	end	
	else begin
		if(sl_HSEL && sl_HREADY && ((sl_HTRANS == `TRANS_NONSEQ) || (sl_HTRANS == `TRANS_SEQ)))
		begin
			q_sel_sl_reg <= sl_HADDR[W_REGS+W_WB_DATA-1:W_WB_DATA];
			q_ld_sl_reg <= sl_HWRITE;
		end
		else begin
			q_ld_sl_reg <= 1'b0;
		end
	end
end	
//----------------------------------------------------------
// Decode Stage: Data Phase
//----------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin
	if(~HRESETn)
	begin
		//control
		alu_op_i <= 4'h0;
		alu_a_i <= 32'h0;
		alu_b_i <= 32'h0;
		a_signed <= 1'b0;
		b_signed <= 1'b0;
	end 
	else begin
		//data-transfer state(data phase)
		if(q_ld_sl_reg == 1)
		begin
			case(q_sel_sl_reg) 
				REG_MUL_OP_I: alu_op_i <= sl_HWDATA;
				REG_MUL_A_I: alu_a_i <= sl_HWDATA;
				REG_MUL_B_I: alu_b_i <= sl_HWDATA;
				REG_MUL_A_SIGNED: a_signed <= sl_HWDATA;
				REG_MUL_B_SIGNED: b_signed <= sl_HWDATA;	
			endcase
		end
	end
end

assign out_sl_HREADY = 1'b1;
assign out_sl_HRESP = `RESP_OKAY;
always @*
begin:rdata
	out_sl_HRDATA = 32'b0;
	case(q_sel_sl_reg) 
		REG_MUL_OP_I: out_sl_HRDATA = alu_op_i;
		REG_MUL_A_I: out_sl_HRDATA = alu_a_i;
		REG_MUL_B_I: out_sl_HRDATA = alu_b_i;
		REG_MUL_A_SIGNED: out_sl_HRDATA = a_signed;
		REG_MUL_B_SIGNED: out_sl_HRDATA = b_signed;	
		REG_MUL_P_O_LO: out_sl_HRDATA = alu_p_o[31:0];
		REG_MUL_P_O_HI: out_sl_HRDATA =  alu_p_o[63:32];
		REG_MUL_EX_STALL: out_sl_HRDATA = ex_stall_mul_w;
	endcase		
end
//----------------------------------------------------------
// Components
//----------------------------------------------------------				
riscv_multiplier
u_multiplier(
./*input */clk_i(HCLK),
./*input */reset_i(HRESETn),
./*input [3:0]  */id_alu_op_r(alu_op_i),
./*input 		*/id_a_signed_r(a_signed),
./*input 		*/id_b_signed_r(b_signed),
./*input [31:0] */id_ra_value_r(alu_a_i),
./*input [31:0] */id_rb_value_r(alu_b_i),
./*output [63:0] */mul_res_w(alu_p_o),
./*output 		*/ex_stall_mul_w(ex_stall_mul_w)
);
endmodule
