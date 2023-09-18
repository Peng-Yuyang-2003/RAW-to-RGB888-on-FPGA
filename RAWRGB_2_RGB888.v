/*-----------------------------------------------------------------------
Filename			:		RAWRGB_2_RGB888.v
Description			:		Convert RAW RGB to RGB888 format.
----------------------------------------------------------------------*/ 

module RAWRGB_2_RGB888
#(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)
(
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//CMOS data output
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal

	input		[7:0]	per_img_RAW,		//Prepared Image data 8 Bit RAW Data

	
	//CMOS RGB888 data output
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output		[7:0]	post_img_red,		//Prepared Image green data to be processed	
	output		[7:0]	post_img_green,		//Prepared Image green data to be processed
	output		[7:0]	post_img_blue		//Prepared Image blue data to be processed
);

reg [9:0] col1=10'b1;
reg [9:0] col2=10'b1;
reg [1:0] row1;
reg [1:0] row2;
reg [7:0] mem [3:0][641:0];  // Matrix storage 4行642列
reg [1567:0] post_frame_href1;
reg [1567:0] post_frame_vsync1;
reg [7:0] post_img_red1;
reg [7:0] post_img_blue1;
reg [7:0] post_img_green1;
////////////行、帧有效信号全部延时1568个时钟周期
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		post_frame_href1<=1568'b0;
	end
	else begin
  		post_frame_href1 <= {post_frame_href1[1566:0], per_frame_href};
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		post_frame_vsync1<=1568'b0;
	end
	else begin
  		post_frame_vsync1 <= {post_frame_vsync1[1566:0], per_frame_vsync};
	end
end
///////////写入数据到mem
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		col1 <= 1;
		row1 <= 0;
	end
	else if (per_frame_href) begin//行有效
		mem[row1][col1] <= per_img_RAW;//写入信号
			if(col1==640) begin//到达列尾
				col1 <= 10'b1;//回到列首
				row1 <= row1+2'b1;//行号加一
			end
			else begin
				col1 <= col1+10'b1;//没到列尾，列号加一
			end
	end
	else begin
		col1 <= 10'b1;//行无效，回到列首
	end
end
///////////从mem读出数据
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		row2 <= 0;
		col2 <= 1;
		post_img_red1 <= 0;
		post_img_green1 <= 0;
		post_img_blue1 <= 0;
	end
	else if (post_frame_href1[1567]) begin//行有效
		case({col2[0],row2[0]})//BGGR阵列
			2'b01:  // b中心
			begin
				post_img_blue1 <= mem[row2][col2-1]/8'b00000010 + mem[row2][col2+1]/8'b00000010;
				post_img_green1 <= mem[row2][col2];
				post_img_red1 <= mem[row2-1][col2]/8'b00000010 + mem[row2+1][col2]/8'b00000010;
			end    
			2'b11:  // g中心
			begin
				post_img_blue1 <= mem[row2-1][col2]/18'b00000010 + mem[row2+1][col2]/8'b00000010;
				post_img_green1 <= mem[row2][col2];
				post_img_red1 <= mem[row2][col2-1]/8'b00000010 + mem[row2][col2+1]/8'b00000010;
			end 
			2'b00:  // g中心
			begin
				post_img_blue1 <= mem[row2][col2-1]/8'b00000010+ mem[row2][col2+1]/8'b00000010;
				post_img_green1 <= mem[row2][col2];
				post_img_red1 <= mem[row2-1][col2]/8'b00000010+ mem[row2+1][col2]/8'b00000010;
			end 
			2'b10:  // b中心
			begin
				post_img_blue1 <= mem[row2][col2];
				post_img_green1 <= mem[row2-1][col2]/8'b00000100+ mem[row2][col2-1]/8'b00000100+ mem[row2][col2+1]/8'b00000100 + mem[row2+1][col2]/8'b00000100;
				post_img_red1 <= mem[row2-1][col2-1]/8'b00000100 + mem[row2-1][col2+1]/8'b00000100 + mem[row2+1][col2-1]/8'b00000100 + mem[row2+1][col2+1]/8'b00000100;
			end                                                    
			default:
			begin
				post_img_red1 <= 8'b0;
				post_img_green1 <= 8'b0;
				post_img_blue1 <= 8'b0;
			end
		endcase
		if(col2==640) begin//到达列尾
			col2 <= 10'b1;
			row2 <=row2+2'b1;
		end
		else begin
			col2 <= col2+10'b1;//没到列尾，列号加一
		end
  	end
	else begin
		col2 <= 10'b1;//行无效，回到列首
	end
end

assign post_frame_href = post_frame_href1[1567];
assign post_frame_vsync = ~post_frame_vsync1[1567];
assign post_img_red=post_img_red1;
assign post_img_blue=post_img_blue1;
assign post_img_green=post_img_green1;
endmodule
