//
//  Player.swift
//  ChessDemo
//
//  Created by Johnson on 16/6/25.
//  Copyright © 2016年 Johnson. All rights reserved.
//

import UIKit
import EVReflection

//棋手角色  1-兵  2-炮   hh
enum Role :Int{
    case Soldier = 1,Cannon
}

class Player :EVObject{
    
    var prole:Int = Role.Soldier.rawValue
    
    var uuid:String = ""
    
    
    //等待 和 进行中状态
    var status:Int = 0

    var otherUuid:String = ""//对手uuid
    
    //当前由轮到谁下棋 ===========
    var turn = Role.Soldier.rawValue
    
    
    var myWin:Bool = false

    //棋子类型
    var type:Int = Role.Soldier.rawValue
    
    var ox:Int = 0
    
    var oy:Int = 0
    
    var nx:Int = 0
    
    var ny:Int = 0
    

    
    required init() {
        super.init()
        //fatalError("init() has not been implemented")
    }
}