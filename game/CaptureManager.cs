using Godot;
using System;
using System.Collections.Generic;
using Godot.Collections;

public partial class CaptureManager : Node2D
{
    private Node _global;
    private Node _stoneManager;

    [Export] public float CaptureCheckInterval = 0.2f;
    [Export] public float PointCheckInterval = 0.2f;

    [Export]public float debug_alpha = 0.1f;

    private float _capture_timer = 0.0f;
    private float _point_timer = 0.0f;

    private List<(Vector2, Vector2)> _debugConnections = new List<(Vector2, Vector2)>();
    private List<(Vector2[], Color)> _debugPolygons = new List<(Vector2[], Color)>();

    public override void _Ready()
    {
        _global = GetNode("/root/Global");
        _stoneManager = GetNode("/root/StoneManager");
        ZIndex = 10;
    }

    public override void _PhysicsProcess(double delta)
    {
        _capture_timer += (float)delta;
        if (_capture_timer >= CaptureCheckInterval)
        {
            _capture_timer = 0.0f;
            RunCaptureLogic();
            QueueRedraw();
        }

        _point_timer += (float)delta;
        if (_point_timer >= PointCheckInterval)
        {
            _point_timer = 0.0f;
            UpdateTerritoryScore();
        }

    }


    public override void _Draw()
    {
        // 1. Draw the adjacency lines (the graph edges)
        foreach (var connection in _debugConnections)
        {
            // Center-to-center thin line
            DrawLine(ToLocal(connection.Item1), ToLocal(connection.Item2), Colors.Cyan, debug_alpha);
        }

        // 2. Draw the detected cycles as semi-transparent polygons
        foreach (var polyData in _debugPolygons)
        {
            Vector2[] localPoints = new Vector2[polyData.Item1.Length];
            for (int i = 0; i < polyData.Item1.Length; i++)
                localPoints[i] = ToLocal(polyData.Item1[i]);

            if (localPoints.Length >= 3)
            {
                DrawColoredPolygon(localPoints, polyData.Item2);
            }
        }
    }


    public void UpdateTerritoryScore()
    {
        var stones = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        float zoneRadius = (float)_global.Get("zone_radius");
        float radiusSq = zoneRadius * zoneRadius;

        float p1Current = 0.0f;
        float p2Current = 0.5f; 

        foreach (var stone in stones)
        {
            if (!IsInstanceValid(stone)) continue;
            if (stone.GlobalPosition.LengthSquared() <= radiusSq)
            {
                if (stone.IsInGroup("P1")) p1Current += 1;
                if (stone.IsInGroup("P2")) p2Current += 1;
            }
        }

        _global.Set("p1_score", p1Current);
        _global.Set("p2_score", p2Current);
        _global.EmitSignal("score_updated", p1Current, p2Current);
    }

    private Shape2D GetStoneShape(RigidBody2D stone)
    {
        // Search children for any collision shape
        foreach (var child in stone.GetChildren())
        {
            if (child is CollisionShape2D cs) return cs.Shape;
            if (child is CollisionPolygon2D cp)
            {
                // Convert polygon to a ConvexPolygonShape2D
                var shape = new ConvexPolygonShape2D();
                shape.Points = cp.Polygon;
                return shape;
            }
        }
        return null;
    }

    private void RunCaptureLogic()
    {
        _debugConnections.Clear();
        _debugPolygons.Clear();

        DetectAndProcessCaptures("P1", "P2"); // P1 creates loops to capture P2
        DetectAndProcessCaptures("P2", "P1"); // P2 creates loops to capture P1
    }

    private void DetectAndProcessCaptures(string team, string opponent)
    {
        var allStones = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        var teamStones = new List<RigidBody2D>();
        var opponentStones = new List<RigidBody2D>();

        foreach (var s in allStones)
        {
            if (s.IsInGroup(team)) teamStones.Add(s);
            else if (s.IsInGroup(opponent)) opponentStones.Add(s);
        }

        if (teamStones.Count < 3) return; // Need at least 3 stones for a loop

        // 1. Build Adjacency Graph
        var adj = BuildAdjacency(teamStones);

        foreach (var kvp in adj)
        {
            foreach (var neighbor in kvp.Value)
            {
                _debugConnections.Add((kvp.Key.GlobalPosition, neighbor.GlobalPosition));
            }
        }

        // 2. Find Cycles
        var cycles = FindCycles(teamStones, adj);

        // 3. Check for victims in each cycle
        var capturedStones = new HashSet<RigidBody2D>();
        Color polyColor = team == "P1" ? new Color(0.1f, 0.1f, 0.1f, debug_alpha) : new Color(0.9f, 0.9f, 0.9f, debug_alpha);
        
        foreach (var cycle in cycles)
        {
            Vector2[] polygon = new Vector2[cycle.Count];
            for (int i = 0; i < cycle.Count; i++) polygon[i] = cycle[i].GlobalPosition;

            _debugPolygons.Add((polygon, polyColor));

            foreach (var victim in opponentStones)
            {
                if (Geometry2D.IsPointInPolygon(victim.GlobalPosition, polygon))
                {
                    capturedStones.Add(victim);
                }
            }
        }

        // 4. Execute Captures
        foreach (var victim in capturedStones)
        {
            victim.Call("on_captured");
        }
    }

    private System.Collections.Generic.Dictionary<RigidBody2D, List<RigidBody2D>> BuildAdjacency(List<RigidBody2D> stones)
    {
        var adj = new System.Collections.Generic.Dictionary<RigidBody2D, List<RigidBody2D>>();
        var spaceState = GetWorld2D().DirectSpaceState;

        foreach (var s in stones)
        {
            adj[s] = new List<RigidBody2D>();
            var query = new PhysicsShapeQueryParameters2D();
            
            var shape = GetStoneShape(s);
            if (shape == null) continue;
            query.Shape = shape;
            
            query.Transform = s.GlobalTransform;
            query.CollideWithAreas = false;
            query.CollideWithBodies = true;
            query.Exclude = new Array<Rid> { s.GetRid() };

            var results = spaceState.IntersectShape(query);
            foreach (var result in results)
            {
                var neighbor = result["collider"].As<RigidBody2D>();
                if (stones.Contains(neighbor))
                {
                    adj[s].Add(neighbor);
                }
            }
        }
        return adj;
    }

    private List<List<RigidBody2D>> FindCycles(List<RigidBody2D> stones, System.Collections.Generic.Dictionary<RigidBody2D, List<RigidBody2D>> adj)
    {
        var cycles = new List<List<RigidBody2D>>();
        var visited = new HashSet<RigidBody2D>();

        foreach (var startNode in stones)
        {
            if (visited.Contains(startNode)) continue;

            var parent = new System.Collections.Generic.Dictionary<RigidBody2D, RigidBody2D>();
            var stack = new Stack<RigidBody2D>();
            stack.Push(startNode);

            while (stack.Count > 0)
            {
                var current = stack.Pop();
                if (!visited.Contains(current))
                {
                    visited.Add(current);
                    foreach (var neighbor in adj[current])
                    {
                        if (!visited.Contains(neighbor))
                        {
                            parent[neighbor] = current;
                            stack.Push(neighbor);
                        }
                        else if (parent.ContainsKey(current) && neighbor != parent[current])
                        {
                            // Cycle detected! Backtrace to build the cycle list
                            var cycle = new List<RigidBody2D> { neighbor, current };
                            var temp = current;
                            while (parent.ContainsKey(temp) && parent[temp] != neighbor)
                            {
                                temp = parent[temp];
                                cycle.Add(temp);
                            }
                            cycles.Add(cycle);
                        }
                    }
                }
            }
        }
        return cycles;
    }
}