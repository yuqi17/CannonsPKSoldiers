//
//  ChessBoradView.swift
//  ChessDemo
//
//  Created by Johnson on 16/5/23.
//  Copyright © 2016年 Johnson. All rights reserved.
//

import UIKit


protocol ChessBoradViewDelegate : class {
    
    func refresh() -> [[Int]]
    
}


//@IBDesignable
class ChessBoradView: UIView {
    
    
    var lineCount:Int = 6
    
    var len:Int{
        return lineCount - 1
    }
    
    
    var delegate:ChessBoradViewDelegate?
    
    var  distance :CGFloat{
        return bounds.width / CGFloat(len)
    }
    
    
    override func drawRect(rect: CGRect) {
        
        //绘制棋盘
        let path = UIBezierPath()
        UIColor.blackColor().setStroke()
        path.lineWidth = 1
        
        for i in 0 ... len
        {
    
            path.moveToPoint( CGPointMake( CGFloat(i) * distance ,  0)   )
            path.addLineToPoint(  CGPointMake( CGFloat(i) * distance , bounds.width)   )

            path.moveToPoint( CGPointMake(0 ,  CGFloat(i) * distance )   )
            path.addLineToPoint(  CGPointMake(bounds.width , CGFloat(i) * distance)   )
            
            path.stroke()
            
        }
        
        //绘制棋子
        
        for subView in subviews
        {
            subView.removeFromSuperview()
        }
        
        var arr =  delegate!.refresh()
        
        let d = distance / 3
        let offset = d / 2

        
        for row in 0 ... len
        {
            for column in 0 ... len
            {
                
                let chessMan = UIView(frame: CGRect(x:CGFloat(row)*distance - offset, y: CGFloat(column)*distance - offset, width: d, height: d))
                chessMan.layer.cornerRadius = offset
                
                switch arr[column][row] {
                case 1:
                    chessMan.backgroundColor = UIColor.blueColor()

                case 2:
                    chessMan.backgroundColor = UIColor.redColor()

                default:
                    break
                }

                addSubview(chessMan)
                
            }
        }

    }

}
