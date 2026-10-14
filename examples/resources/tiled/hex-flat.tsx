<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" name="Sample terrain" tilewidth="64" tileheight="48" tilecount="3" columns="3">
 <image source="hex-flat.png" width="192" height="48"/>
 <tile id="0" type="Grass"/>
 <tile id="1" type="Mud"><properties><property name="AStar" type="class"><properties>
  <property name="aspects" type="class"><properties><property name="mud" type="float" value="0.75"/></properties></property>
 </properties></property></properties></tile>
 <tile id="2" type="Wall"><properties><property name="AStar" type="class"><properties>
  <property name="passable" type="bool" value="false"/>
 </properties></property></properties></tile>
</tileset>
