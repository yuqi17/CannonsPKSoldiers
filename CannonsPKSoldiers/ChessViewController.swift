//
//  ViewController.swift
//  ChessDemo
//
//  Created by Johnson on 16/5/23.
//  Copyright © 2016年 Johnson. All rights reserved.
//

import UIKit
import SwiftWebSocket


class ChessViewController: UIViewController,ChessBoradViewDelegate {
    
    //用来记录每次棋子变动的位置
    private var chessArr:[[Int]] = [
        [1,1,1,1,1,1],
        [1,1,1,1,1,1],
        [1,1,1,1,1,1],
        [0,0,0,0,0,0],
        [0,2,0,0,2,0],
        [0,0,0,0,0,0]
    ]
    
    private var ws = WebSocket("ws://192.168.1.3:8080/game/ws")
    
    private var lastStep :(Int,Int) = (0,0)
    
    
    private var turn:Int = 1
    
    private var step:Int = 0
    
    private var player:Player?
    
    
    
    @IBOutlet weak var chessBoard: ChessBoradView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chessBoard.delegate = self
        
        
        ws.event.open = {
            print("连接服务器成功!!")
        }
        
        ws.event.close = { (code, reason, clean) in
            print("服务器已经关闭")
        }
        
        ws.event.error = { error in
            print("错误: \(error)")
        }
        
        ws.event.message = onMessage
        
        
    }
    
    func onMessage(data:Any){
        
        
        let string = data as! String
        
        //String 转 NSData
        //let nsdata = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        //let json = JSON(data: nsdata!)
        
        
        let firstNew = Player(json: string)
        if(player == nil)
        {
            //身份已经确定
            player = firstNew
            
        }
        else
        {
            player?.ox = firstNew.ox
            player?.oy = firstNew.oy
            player?.nx = firstNew.nx
            player?.ny = firstNew.ny
            player?.turn = firstNew.turn
            player?.status = firstNew.status
        }
        print(string)
        
        //下棋状态
        if player?.status == 2 {
            
            if player?.turn == Role.Cannon.rawValue {
                chessArr[(player?.ox)!][(player?.oy)!] = 0
                chessArr[(player?.nx)!][(player?.ny)!] = Role.Soldier.rawValue
            }
            else if player?.turn == Role.Soldier.rawValue
            {
                chessArr[(player?.ox)!][(player?.oy)!] = 0
                chessArr[(player?.nx)!][(player?.ny)!] = Role.Cannon.rawValue
            }
            
            self.chessBoard.setNeedsDisplay()
        }
        else if player?.status == 3 //已经确定输赢
        {
            showMessage(checkWhoWin() == player!.prole)
        }
        
        
        
    }
    
    
    func refresh() -> [[Int]]
    {
        return self.chessArr
    }
    
    
    @IBAction func tap(gesture: UITapGestureRecognizer) {
        
        
        let tapPoint = gesture.locationInView(chessBoard)
        
        let pointInView = chessBoard.convertPoint(tapPoint, toView: view)
        
        let column = Int(pointInView.x / chessBoard.distance)
        let row    = Int(pointInView.y / chessBoard.distance)
        
        
        if step == 0 //选中棋子
        {
            if chessArr[row][column] ==  player?.turn//已经被选中
            {
                lastStep = (row,column)
                //print("\(row):\(column) ---> \(chessArr[row][column])")
                step = 1
            }
            
        }
        else if step == 1//选中落子位置
        {
            step = 0
            
            //没有轮到当前玩家下
            if player?.turn  != player?.prole {
                return
            }
            
            
            let drow    = row - lastStep.0
            let dcolumn = column - lastStep.1
            
            let distance = sqrt(Double(drow*drow + dcolumn*dcolumn))
            
            
            if player?.prole == Role.Soldier.rawValue {
                
                //兵只能一次走一步
                if  distance != 1
                {
                    return
                }
                
                //落子的位置必须是空位
                if chessArr[row][column] != 0 {
                    return
                }
                
                //本地棋盘更新
                chessArr[lastStep.0][lastStep.1] = 0
                chessArr[row][column] = 1
                
                
                player?.ox = lastStep.0
                player?.oy = lastStep.1
                player?.nx = row
                player?.ny = column
                
                player?.turn = Role.Cannon.rawValue
                
                ws.send(text: (player?.toJsonString())!)
                
            }
            else if player?.prole == Role.Cannon.rawValue {
                
                if distance != 1 && distance != 2 {
                    return
                }
                
                if distance == 1
                {
                    if chessArr[row][column] != 0 {
                        return
                    }
                }
                
                if distance == 2 {
                    
                    if chessArr[row][column] != 1{
                        return
                    }
                    
                    if dcolumn == 2 {
                        if chessArr[lastStep.0][lastStep.1 + 1] == 1
                        {
                            return
                        }
                    }
                    
                    if dcolumn == -2 {
                        if chessArr[lastStep.0][lastStep.1 - 1] == 1
                        {
                            return
                        }
                    }
                    
                    if drow == 2 {
                        if chessArr[lastStep.0 + 1][lastStep.1] == 1
                        {
                            return
                        }
                    }
                    
                    if drow == -2 {
                        if chessArr[lastStep.0 - 1][lastStep.1] == 1
                        {
                            return
                        }
                    }
                    
                }
                
                
                chessArr[lastStep.0][lastStep.1] = 0
                chessArr[row][column] = 2
                
                
                //网络发送
                player?.ox = lastStep.0
                player?.oy = lastStep.1
                player?.nx = row
                player?.ny = column
                
                player?.turn = Role.Soldier.rawValue
                
                ws.send(text: (player?.toJsonString())!)
            }//
            
            
            self.chessBoard.setNeedsDisplay()
            
            handleResult()
            
        }
        
        
    }
    
    
    private func handleResult(){
        
        //网络发送
        if checkWhoWin() != -1 {
            
            player?.myWin = (checkWhoWin() == player!.prole)
            
            if player!.myWin {
                player?.status = 3
                player?.turn = Role.Soldier.rawValue
                ws.send(text: player!.toJsonString())
            }
            
            showMessage(player!.myWin)
        }
        
        
    }
    
    private func showMessage(isWin:Bool){
        let title = "消息:"
        let message = isWin  ? "你赢了" : "你输了"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "确 定", style: UIAlertActionStyle.Default) {
            action in
            
//            if self.checkWhoWin() == Role.Cannon.rawValue
//            {
//                self.chessArr = [
//                    [1,1,1,1,1,1],
//                    [1,1,1,1,1,1],
//                    [1,1,1,1,1,1],
//                    [0,0,0,0,0,0],
//                    [0,2,0,0,2,0],
//                    [0,0,0,0,0,0]
//                ]
//                
//            }
//            else
//            {
//                self.chessArr = [
//                    [0,0,0,0,0,0],
//                    [0,2,0,0,2,0],
//                    [0,0,0,0,0,0],
//                    [1,1,1,1,1,1],
//                    [1,1,1,1,1,1],
//                    [1,1,1,1,1,1]
//                ]
//            }
//            
//            self.chessBoard.setNeedsDisplay()
            
        }
        
        alert.addAction(okAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func checkWhoWin() -> Int{
        
        var countb = 0
        var countpq = 0
        
        for row in 0 ... 5
        {
            for column in 0 ... 5{
                
                if chessArr[row][column] == 1 {
                    countb += 1
                }
                
                if chessArr[row][column] == 2{
                    
                    if row - 1 >= 0{
                        if chessArr[row - 1][column] == 0 {
                            countpq += 1
                        }
                    }
                    
                    if row + 1 <= 5{
                        if chessArr[row + 1][column] == 0 {
                            countpq += 1
                        }
                    }
                    
                    if column - 1 >= 0{
                        if chessArr[row][column - 1] == 0 {
                            countpq += 1
                        }
                    }
                    
                    if column + 1 <= 5{
                        if chessArr[row][column + 1] == 0 {
                            countpq += 1
                        }
                    }
                    
                }
            }
        }
        
        //没有兵               兵输
        if  countb == 0 {
            return 2
        }
        
        //所有炮的周围没有空位    炮输
        if  countpq == 0 {
            return 1
        }
        
        //其他情况,人工决定
        return -1
    }
    
    
    
    
}

