<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>채팅목록</title>
<link
	href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css"
	rel="stylesheet"
	integrity="sha384-rbsA2VBKQhggwzxH7pPCaAqO46MgnOM80zW1RWuH61DGLwZJEdK2Kadq2F9CUG65"
	crossorigin="anonymous">
<script
	src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.6/dist/umd/popper.min.js"
	integrity="sha384-oBqDVmMz9ATKxIep9tiCxS/Z9fNfEXiDAYTujMAeBAsjFuCZSmKbSSUnQlmh/jp3"
	crossorigin="anonymous"></script>
<script
	src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.min.js"
	integrity="sha384-cuYeSxntonz0PPNlHhBs68uyIAVpIIOZZ5JqeqvYYIcEL727kskC66kF92t6Xl2V"
	crossorigin="anonymous"></script>
<script
	src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
<script
	src="https://cdnjs.cloudflare.com/ajax/libs/sockjs-client/1.6.1/sockjs.min.js"></script>
<script
	src="https://cdnjs.cloudflare.com/ajax/libs/stomp.js/2.3.3/stomp.min.js"></script>
<link
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.css"
	type="text/css" rel="stylesheet">
<link rel="stylesheet" href="resources/css/roomSelectOne.css">
<jsp:include page="../css.jsp"></jsp:include>

<!-- 디자인 : https://bootsnipp.com/snippets/1ea0N -->

<script type="text/javascript">
	
	$(function(){
		var headers = null;
		var roomNum = null;
		var user_id = '${user_id}';
		var boardType = null;
		var boardNum = null;
		var boardStatus = null;
		
		function handleMessageReceived(message) {
		    var msg = JSON.parse(message.body);
		    // 메시지를 받은 방의 roomNum과 unreadCount 정보를 사용하여 업데이트
		    updateReadCount(msg.room_num, msg.unread_count);
		  }
		
		$('.chat_list #delete').click(function(event) {
		    event.stopPropagation();
// 		    console.log('Button clicked');
		    
		    roomNum = $(this).data('roomnum');
// 		    console.log(roomNum);
		    
		    if(confirm('채팅방을 정말 삭제하시겠습니까? 채팅 내역이 다 사라집니다. ')){
		    	if('${user_id}'===''){
// 					console.log('널입니다.');
					location.href = 'login.do';
				}
		    	$.ajax({
					url:"jsonRoomDelete.do",
					data:{room_num:roomNum},
					method:'GET',
					dataType:'json',
					success:function(result){
// 						console.log('ajax success:',result);
						
						if(result==1){
							location.href = 'roomSelectAll.do';
						}
						
					},
					error:function(xhr,status,error){
						console.log('xhr:',xhr.status);
					}
				});
		    }else{
		    	
		    }
		  });
		
		var currentStompConnection = null;
		$('.chat_list').click(function(){
			roomNum = $(this).data('roomnum');
			boardType = $(this).data('boardtype');
			boardNum = $(this).data('boardnum');
			boardStatus = $(this).data('boardstatus');
// 			console.log('chat_list click ',roomNum);
// 			console.log('user_id : ',user_id);
// 			console.log('boardType : ',boardType);
// 			console.log('boardNum : ',boardNum);
// 			console.log('boardStatus : ',boardStatus);
			
			if('${user_id}'===''){
// 				console.log('널입니다.');
				location.href = 'login.do';
			}
			
			if (currentStompConnection !== null) {
				currentStompConnection.disconnect();
		        currentStompConnection = null;
		        $(".msg_send_btn").off("click");
		    }

			var sockJs = new SockJS('/idle/chat/'+roomNum+'/info');
			var stomp = Stomp.over(sockJs);
			currentStompConnection = stomp;
			
			var otherId = selectOneRoom(roomNum, user_id);
			
			headers = {
					'connect-user-id': user_id
			};
// 			console.log("header:", headers)
				
				stomp.connect(headers,function(frame){
// 					console.log('Connected : '+frame);
// 					console.log('연결 성공!');
					
					readCheck(roomNum);
					
					readCount(roomNum,user_id);
					
					$('.msg_history').empty();
					$('#buyCheck').empty();
					
					if(boardStatus==2){
						let buyCheck = `<h3>거래완료된 채팅입니다.</h3>`;
						$('#buyCheck').html(buyCheck);
					}else{
						let buyCheck = `<h3>채팅방 입니다.</h3>`;
						$('#buyCheck').html(buyCheck);
					}
					
					$.ajax({
						url:"jsonRoomCheck.do",
						data:{room_num:roomNum},
						method:'GET',
						dataType:'json',
						success:function(vo){
							if(user_id===vo.seller&&boardStatus==1){
// 								console.log('구매확정요청 생성!');
								let buyCheck = `<button class="btn btn-primary" type="button" onclick="buyRequest(\${roomNum},'\${vo.seller}')">구매확정요청</button>`;
								$('#buyCheck').html(buyCheck);
							}
						},
						error:function(xhr,status,error){
							console.log('xhr:',xhr.status);
						}
					});
					
					$.ajax({
						url:"jsonMessageSelectAll.do",
						data:{room_num:roomNum},
						method:'GET',
						dataType:'json',
						success:function(vos){
// 							console.log('ajax success:',vos);
							
							let str = ``;
							
							$.each(vos,function(index,vo){
								let date = new Date(vo.message_date).toLocaleString();
								if(vo.message_type==1){
									if (vo.sender === user_id) {
										str += `
											<div class="outgoing_msg">
								              <div class="sent_msg">
								             	<div align="right">\${vo.sender}</div>
								                <p>\${vo.message}</p>
								                <span class="time_date">\${date}</span> </div>
								            </div>
										`;
									} else {
										str += `
											<div class="incoming_msg">
								              <div class="incoming_msg_img"> <img src="resources/img/thumb_\${vo.sender_savename }"> </div>
								              <div class="received_msg">
								              	<p>\${vo.sender}</p>
								                <div class="received_withd_msg">
								                  <p>\${vo.message}</p>
								                  <span class="time_date">\${date}</span></div>
								              </div>
								            </div>
										`;
									}
								}else{
									if(vo.sender!==user_id&&boardStatus==1){
										let buyCheck = `<button class="btn btn-primary" type="button" onclick="buyInsert(\${boardNum},'\${user_id}',\${boardType})">구매확정하기</button>`;
										$('#buyCheck').html(buyCheck);
									}
								}
							});
							$('.msg_history').append(str);
							prepareScroll();
							
						},
						error:function(xhr,status,error){
							console.log('xhr:',xhr.status);
						}
					});
					
					
					stomp.subscribe("/sub/chat/room/" + roomNum, function(message) {
// 						console.log(message);
						var msg = JSON.parse(message.body);
						
						let str = ``;
						
						let date = new Date(msg.message_date).toLocaleString();
						
						let imgnum = jQuery('#'+roomNum).attr("src");
// 						console.log(imgnum);

						if (msg.sender === user_id) {
							
							str += `
								<div class="outgoing_msg">
					              <div class="sent_msg">
					              	<div align="right">\${msg.sender}</div>
					                <p>\${msg.message}</p>
					                <span class="time_date">\${date}</span> </div>
					            </div>
							`;
							$('.msg_history').append(str);

						} else {
							str += `
								<div class="incoming_msg">
					              <div class="incoming_msg_img"> <img src="\${imgnum}"> </div>
					              <div class="received_msg">
					              	<p>\${msg.sender}</p>
					                <div class="received_withd_msg">
					                  <p>\${msg.message}</p>
					                  <span class="time_date">\${date}</span></div>
					              </div>
					            </div>
							`;
							$('.msg_history').append(str);
							
							readCheck(roomNum);
							readCount(roomNum,user_id);
							prepareScroll();
						}
					});
					stomp.subscribe("/sub/chat/roomDeleted" + roomNum, function(result){
// 						console.log(result);
						
						let str = `
							<div class="incoming_msg">
				              <div class="incoming_msg_img"></div>
				              <div class="received_msg">
				                <div class="received_withd_msg">
				                  <p>상대방이 채팅방을 삭제했습니다. 더이상 채팅을 진행할 수 없습니다.</p>
				                  <span class="time_date"></span></div>
				              </div>
				            </div>
						`;
						$('.msg_history').append(str);
						prepareScroll();
					});
					
					stomp.subscribe("/sub/chat/buyRequest" + roomNum, function(message){
// 						console.log(message);
						var msg = JSON.parse(message.body);
						
						if(msg.sender!==user_id&&boardStatus==1){
							let buyCheck = `<button class="btn btn-primary" type="button" onclick="buyInsert(\${boardNum},'\${user_id}',\${boardType})">구매확정하기</button>`;
							$('#buyCheck').html(buyCheck);
						}
						readCheck(roomNum);
						readCount(roomNum,'${user_id}');
						
					});
					
					
					
					prepareScroll();
					
				});
				
				$(".msg_send_btn").on("click", function(e) {
					var msg = document.getElementById("msg");

// 					console.log(user_id + " : " + msg.value);
					stomp.send('/pub/chat/message', {}, JSON.stringify({
						room_num : roomNum,
						message : msg.value,
						sender : user_id
					}));
					msg.value = '';
					readCheck(roomNum);
					readCount(roomNum,user_id);
					prepareScroll();
				});
				

		});
		
		$('#msg').keyup(function(event){
			if(event.which === 13){
				$("#bt").click();
			}
		});
	});
	
	function scrollUI(){
		let chatUI = document.querySelector('.msg_history');
		chatUI.scrollTop = chatUI.scrollHeight;
	}
	
	function prepareScroll() {
		  window.setTimeout(scrollUI, 50);
		}
	
	function readCheck(roomNum){
// 		console.log('방 입장 후 읽음으로 변경');
		$.ajax({
			url:"readCheck.do",
			data:{
				room_num: roomNum,
				sender: '${user_id}'
			},
			method: 'post',
			dataType: 'json',
			success: function(result){
// 				console.log('result : ',result);
			},
			error: function(xhr, status, error) {
	            console.log('xhr:', xhr.status);
	        }
		});
	}
	
	function readCount(roomNum,user_id){
// 		console.log('방 입장 후 안읽은 메세지수 변경');
		$.ajax({
			url: 'jsonReadCount.do',
			data: {
				room_num:roomNum,
				sender:user_id
			},
			method: 'GET',
			dataType: 'json',
			success: function(result){
// 				console.log('안읽은 메세지 수 : ',result);
				if(result>0){
					$('#readCount_'+roomNum).text('안읽은 메세지 수 : '+result);
				}else{
					$('#readCount_'+roomNum).text('');
				}
			},
			error: function(xhr, status, error) {
			      console.log('xhr:', xhr.status);
			}
		});
	}
	
	
	
	function buyRequest(roomNum,seller){
// 		console.log('buyRequest() 클릭',roomNum,seller);
		
		var resultok = confirm("구매 요청을 보내시겠습니까?")
		
		if(resultok){
			$.ajax({
				url:'jsonBuyRequest.do',
				data:{
					room_num:roomNum,
					message:'구매확정요청',
					sender:seller
				},
				method: 'GET',
				dataType:'json',
				success:function(result){
// 					console.log(result);
					if(result==0){
						alert("이미 구매요청을 보냈습니다.");
					}
				},
				error: function(xhr, status, error) {
				      console.log('xhr:', xhr.status);
				}
			});
			
			readCheck(roomNum);
			readCount(roomNum,'${user_id}');
		}
	}
	
	function buyInsert(boardNum,user_id,boardType){
// 		console.log('buyInsert',boardNum,user_id,boardType);
		
		var resultok = confirm("구매 확정 하시겠습니까?")
		
		if(resultok){
			if(boardType==1){
// 				console.log('구해요글');
				$.ajax({
					url:'jsonBuyInsert.do',
					data:{
						board_num:boardNum,
						id:user_id
					},
					method:'GET',
					dataType:'json',
					success:function(result){
// 						console.log(result);
						if(result==1){
							boardStatusChange(boardNum);
						}else if(result==0){
							alert("이미 구매 확정 하셨습니다.");
						}
					},
					error: function(xhr, status, error) {
					      console.log('xhr:', xhr.status);
					}
				});
			}else if(boardType==2){
// 				console.log('팔아요글');
				$.ajax({
					url:'jsonSellInsert.do',
					data:{
						board_num:boardNum,
						id:user_id
					},
					method:'GET',
					dataType:'json',
					success:function(result){
// 						console.log(result);
						if(result==1){
							boardStatusChange(boardNum);
						}if(result==0){
							alert("이미 구매 확정 하셨습니다.");
						}
					},
					error: function(xhr, status, error) {
					      console.log('xhr:', xhr.status);
					}
				});
			}	
		}
	}
	
	function boardStatusChange(boardNum){
// 		console.log('거래완료로 변경하기',boardNum);
		$.ajax({
			url:'jsonChangeStatus.do',
			data:{
				board_num:boardNum,
				board_status:2
			},
			method:'GET',
			dataType:'json',
			success:function(result){
// 				console.log(result);
				if(result==1){
					alert("거래가 완료되었습니다.");
					location.reload(true);
				}else if(result==0){
					alert("이미 거래가 완료된 상품입니다.");
				}
			},
			error: function(xhr, status, error) {
			      console.log('xhr:', xhr.status);
			}
		});
	}
	
	//동기로 처리
	function selectOneRoom(roomNum, user_id) {
	    var otherId = null;
// 	    console.log('채팅 참여자 확인');
	    $.ajax({
	      url: 'jsonRoomSelectOne.do',
	      data: {
	        room_num: roomNum
	      },
	      method: 'GET',
	      async: false,
	      dataType: 'json',
	      success: function(vo2) {
// 	        console.log("chatUsers vo2:", vo2);
	        if (vo2.buyer === user_id) {
	          otherId = vo2.seller;
	        } else {
	          otherId = vo2.buyer;
	        }
	      },
	      error: function(xhr, status, error) {
	        console.log('xhr:', xhr.status);
	      }
	    });
	    return otherId;
	}
	
</script>
</head>
<body>
	<jsp:include page="../top_menu.jsp"></jsp:include>
	<section style="padding-left: 100px; padding-right: 100px;">
		<div class="container">
			<h3 class=" text-center">채팅</h3>
			<h5 id="test"></h5>
			<div class="messaging">
				<div class="inbox_msg">
					<div class="inbox_people">
						<div class="headind_srch">
							<div class="recent_heading">
								<h4>채팅목록</h4>
							</div>
						</div>
						<div class="inbox_chat" id="roomList">
							<c:forEach var="vo" items="${vos }">
								<div class="chat_list" data-roomnum="${vo.room_num }" data-boardtype="${vo.board_type }" data-boardnum="${vo.board_num }" data-boardstatus="${vo.board_status }">
									<div class="chat_people">
										<div class="chat_img">
											<img src="resources/img/thumb_${vo.member_savename }"
												id="${vo.room_num }">
										</div>
										<div class="chat_ib">
											<c:if test="${user_id eq vo.buyer }">
												<c:if test="${vo.readcount ne 0 }">
													<h5 style="color: red;" id="readCount_${vo.room_num }">안읽은
														메세지수 : ${vo.readcount }</h5>
												</c:if>
												<h5>${vo.board_title },
													가격:${vo.price } <span class="chat_date"><button
															id="delete" data-roomnum="${vo.room_num}" class="myButton">삭제</button></span>
												</h5>
												<h5>글쓴이와의 채팅</h5>
												<h5>${vo.seller }
													<span class="chat_date">${vo.room_date }</span>
												</h5>
											</c:if>
											<c:if test="${user_id eq vo.seller }">
												<c:if test="${vo.readcount ne 0 }">
													<h5 style="color: red;" id="readCount_${vo.room_num }">안읽은
														메세지수 : ${vo.readcount }</h5>
												</c:if>
												<h5>${vo.board_title },
													가격:${vo.price } <span class="chat_date"><button
															id="delete" data-roomnum="${vo.room_num}" class="myButton">삭제</button></span>
												</h5>
												<h5>거래희망자와의 채팅</h5>
												<h5>${vo.buyer }
													<span class="chat_date">${vo.room_date }</span>
												</h5>
											</c:if>
										</div>
									</div>
								</div>
							</c:forEach>
						</div>
					</div>

					<div class="mesgs">
						<div id="buyCheck" class="d-grid gap-2 col-6 mx-auto"><h3>채팅방을 눌러주세요</h3></div>
						<hr>
						<div class="msg_history" id="scroll"></div>
						<div class="type_msg">
							<div class="input_msg_write">
								<input type="text" class="write_msg"
									placeholder="Type a message" id="msg" />
								<button class="msg_send_btn" type="button" id="bt">
									<i class="fa fa-paper-plane-o" aria-hidden="true"></i>
								</button>
							</div>
						</div>

					</div>
				</div>
			</div>
		</div>
	</section>
</body>
</html>
