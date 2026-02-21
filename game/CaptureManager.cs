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

    [Export] public float debug_alpha = 0.1f;

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
        foreach (var connection in _debugConnections)
        {
            DrawLine(ToLocal(connection.Item1), ToLocal(connection.Item2), Colors.Cyan, debug_alpha);
        }

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
                if (stone.IsInGroup("P1_Scoring")) p1Current += 1;
                if (stone.IsInGroup("P2_Scoring")) p2Current += 1;
            }
        }

        _global.Set("p1_score", p1Current);
        _global.Set("p2_score", p2Current);
        _global.EmitSignal("score_updated", p1Current, p2Current);
    }

    private Shape2D GetStoneShape(RigidBody2D stone)
    {
        foreach (var child in stone.GetChildren())
        {
            if (child is CollisionShape2D cs) return cs.Shape;
            if (child is CollisionPolygon2D cp)
            {
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

        // P1's capturing stones form loops to capture non-P1_Capturing stones
        DetectAndProcessCaptures("P1_Capturing");
        // P2's capturing stones form loops to capture non-P2_Capturing stones
        DetectAndProcessCaptures("P2_Capturing");
    }

    private void DetectAndProcessCaptures(string capturingGroup)
    {
        var allStones = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        var capturingStones = new List<RigidBody2D>();
        var potentialVictims = new List<RigidBody2D>();

        foreach (var s in allStones)
        {
            if (s.IsInGroup(capturingGroup))
                capturingStones.Add(s);
            else
                potentialVictims.Add(s); // Anything NOT in this capturing group is a potential victim
        }

        if (capturingStones.Count < 3) return;

        // 1. Build Adjacency Graph
        var adj = BuildAdjacency(capturingStones);

        foreach (var kvp in adj)
        {
            foreach (var neighbor in kvp.Value)
            {
                _debugConnections.Add((kvp.Key.GlobalPosition, neighbor.GlobalPosition));
            }
        }

        // 2. Find Cycles
        var cycles = FindCycles(capturingStones, adj);

        // 3. Check for victims in each cycle
        var capturedStones = new HashSet<RigidBody2D>();
        Color polyColor = capturingGroup == "P1_Capturing"
            ? new Color(0.1f, 0.1f, 0.1f, debug_alpha)
            : new Color(0.9f, 0.9f, 0.9f, debug_alpha);

        foreach (var cycle in cycles)
        {
            Vector2[] polygon = new Vector2[cycle.Count];
            for (int i = 0; i < cycle.Count; i++) polygon[i] = cycle[i].GlobalPosition;

            _debugPolygons.Add((polygon, polyColor));

            foreach (var victim in potentialVictims)
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